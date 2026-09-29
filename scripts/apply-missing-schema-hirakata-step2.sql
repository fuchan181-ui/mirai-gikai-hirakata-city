-- ==============================================================================
-- 枚方市版 追加スキーマ適用スクリプト (Step 2: レポート集計・トピック分析・本会議討論)
-- Supabase の SQL Editor に貼り付けて「Run」を実行してください。
-- すでに存在するテーブルや関数があってもエラーが出ない安全な設計 (IF NOT EXISTS) です。
-- ==============================================================================

-- 1. 本会議討論テーブルと関連 enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'debate_stance_enum') THEN
    CREATE TYPE debate_stance_enum AS ENUM ('for', 'against');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS bill_debates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  speaker_name text NOT NULL,
  seat_number integer,
  council_member_id uuid REFERENCES council_members(id) ON DELETE SET NULL,
  stance debate_stance_enum NOT NULL,
  summary text,
  source_url text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bill_id, speaker_name, stance)
);

ALTER TABLE bill_debates ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_bill_debates_bill_id ON bill_debates (bill_id);

ALTER TABLE bills ADD COLUMN IF NOT EXISTS explanation_source text;

-- 2. レポートへのリアクションテーブル
CREATE TABLE IF NOT EXISTS report_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_report_id uuid NOT NULL REFERENCES interview_report(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  reaction_type text NOT NULL CHECK (reaction_type IN ('helpful', 'hmm')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(interview_report_id, user_id)
);

ALTER TABLE report_reactions ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_report_reactions_report_id ON report_reactions(interview_report_id);
CREATE INDEX IF NOT EXISTS idx_report_reactions_user_id ON report_reactions(user_id);

-- 3. ユーザー向けトピック分析テーブル
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'topic_analysis_status') THEN
    CREATE TYPE topic_analysis_status AS ENUM ('pending', 'running', 'completed', 'failed');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS topic_analysis_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  version integer NOT NULL,
  status topic_analysis_status NOT NULL DEFAULT 'pending',
  is_published boolean NOT NULL DEFAULT false,
  current_step text,
  progress jsonb,
  trigger text NOT NULL DEFAULT 'manual',
  model text,
  prompt_version text,
  source_opinion_count integer,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bill_id, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS one_published_per_bill
  ON topic_analysis_version (bill_id) WHERE is_published;

CREATE INDEX IF NOT EXISTS idx_topic_analysis_version_bill ON topic_analysis_version(bill_id);
ALTER TABLE topic_analysis_version ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS topic (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id uuid NOT NULL REFERENCES topic_analysis_version(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_topic_version ON topic(version_id);
ALTER TABLE topic ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS topic_opinion (
  topic_id uuid NOT NULL REFERENCES topic(id) ON DELETE CASCADE,
  opinion_id uuid NOT NULL REFERENCES interview_opinion(id) ON DELETE CASCADE,
  version_id uuid NOT NULL REFERENCES topic_analysis_version(id) ON DELETE CASCADE,
  PRIMARY KEY (version_id, opinion_id)
);

CREATE INDEX IF NOT EXISTS idx_topic_opinion_topic ON topic_opinion(topic_id);
ALTER TABLE topic_opinion ENABLE ROW LEVEL SECURITY;

-- 4. 公開レポート一覧取得 RPC 関数
DROP FUNCTION IF EXISTS find_public_reports_by_bill_id_ordered_by_reactions(UUID, INT);
DROP FUNCTION IF EXISTS find_public_reports_by_bill_id_ordered_by_reactions(UUID, INT, INT, TEXT);
DROP FUNCTION IF EXISTS find_public_reports_by_bill_id_ordered_by_reactions(UUID, INT, INT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION find_public_reports_by_bill_id_ordered_by_reactions(
  p_bill_id UUID,
  p_limit INT DEFAULT 1000,
  p_offset INT DEFAULT 0,
  p_stance TEXT DEFAULT NULL,
  p_sort_order TEXT DEFAULT 'recommended'
)
RETURNS TABLE (
  id UUID,
  stance stance_type_enum,
  role interview_report_role_enum,
  role_title TEXT,
  summary TEXT,
  total_content_richness INTEGER,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ir.id,
    ir.stance,
    ir.role,
    ir.role_title,
    ir.summary,
    ir.total_content_richness,
    ir.created_at
  FROM interview_report ir
  INNER JOIN interview_sessions s ON s.id = ir.interview_session_id
  INNER JOIN interview_configs c ON c.id = s.interview_config_id
  LEFT JOIN (
    SELECT rr.interview_report_id, COUNT(*) AS helpful_count
    FROM report_reactions rr
    WHERE rr.reaction_type = 'helpful'
    GROUP BY rr.interview_report_id
  ) rc ON rc.interview_report_id = ir.id
  WHERE ir.is_public_by_admin = TRUE
    AND ir.is_public_by_user = TRUE
    AND c.bill_id = p_bill_id
    AND (p_stance IS NULL OR ir.stance::TEXT = p_stance)
  ORDER BY
    CASE WHEN p_sort_order = 'newest' THEN NULL
         ELSE (COALESCE(rc.helpful_count, 0) + COALESCE(ir.total_content_richness, 0))
    END DESC NULLS LAST,
    ir.created_at DESC,
    ir.id DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 5. スタンス別公開レポート件数取得 RPC 関数
DROP FUNCTION IF EXISTS count_public_reports_by_stance(UUID);

CREATE OR REPLACE FUNCTION count_public_reports_by_stance(
  p_bill_id UUID
)
RETURNS TABLE (
  stance TEXT,
  count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ir.stance::TEXT AS stance,
    COUNT(*) AS count
  FROM interview_report ir
  INNER JOIN interview_sessions s ON s.id = ir.interview_session_id
  INNER JOIN interview_configs c ON c.id = s.interview_config_id
  WHERE ir.is_public_by_admin = TRUE
    AND ir.is_public_by_user = TRUE
    AND c.bill_id = p_bill_id
  GROUP BY ir.stance;
END;
$$ LANGUAGE plpgsql STABLE;

