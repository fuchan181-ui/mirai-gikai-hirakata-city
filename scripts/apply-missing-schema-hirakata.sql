-- ============================================================
-- みらい議会＠枚方市: 不足スキーマ・RPC関数の追加スクリプト
-- Supabase Dashboard の SQL Editor で一度だけ実行してください。
-- ============================================================

-- 1. enum council_session_kind_enum の安全な作成
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'council_session_kind_enum') THEN
    CREATE TYPE council_session_kind_enum AS ENUM ('regular', 'extraordinary');
  END IF;
END $$;

-- 2. council_sessions カラム追加
ALTER TABLE council_sessions ADD COLUMN IF NOT EXISTS kind council_session_kind_enum NOT NULL DEFAULT 'regular';
ALTER TABLE council_sessions ADD COLUMN IF NOT EXISTS source_url TEXT;
ALTER TABLE council_sessions ADD COLUMN IF NOT EXISTS session_number INTEGER;
ALTER TABLE council_sessions ADD COLUMN IF NOT EXISTS external_council_id TEXT;

-- council_url の値を source_url に同期（未同期の場合）
UPDATE council_sessions SET source_url = council_url WHERE source_url IS NULL AND council_url IS NOT NULL;

-- 3. bills カラム追加
ALTER TABLE bills ADD COLUMN IF NOT EXISTS thumbnail_key TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS is_review_completed BOOLEAN NOT NULL DEFAULT false;

-- 4. 検索テキスト正規化関数
CREATE OR REPLACE FUNCTION normalize_search_text(value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT regexp_replace(lower(normalize(coalesce(value, ''), NFKC)), '[[:space:]　]+', '', 'g');
$$;

COMMENT ON FUNCTION normalize_search_text(text) IS
  '議案検索の比較用正規化。web の search-bills.ts と同じ規則にすること';

-- 5. 議案ステータスグループ分類関数
CREATE OR REPLACE FUNCTION bill_status_group(p_status bill_status_enum)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN p_status IN ('submitted', 'in_committee', 'plenary_session') THEN 'deliberating'
    WHEN p_status IN ('approved', 'adopted', 'partially_adopted') THEN 'enacted'
    WHEN p_status IN ('rejected') THEN 'rejected'
    ELSE 'waiting'
  END;
$$;

COMMENT ON FUNCTION bill_status_group(bill_status_enum) IS
  '一覧タブのグループ分け。web の bill-status-group.ts と同じにすること';

-- 6. 議案ごとの公開レポート件数集計関数
CREATE OR REPLACE FUNCTION public.count_public_reports_by_bill_ids(p_bill_ids uuid[])
RETURNS TABLE (
  bill_id uuid,
  report_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.bill_id,
    COUNT(*) AS report_count
  FROM interview_report r
  JOIN interview_sessions s ON s.id = r.interview_session_id
  JOIN interview_configs c ON c.id = s.interview_config_id
  WHERE c.bill_id = ANY(p_bill_ids)
    AND r.is_public_by_admin
    AND r.is_public_by_user
  GROUP BY c.bill_id;
$$;

COMMENT ON FUNCTION public.count_public_reports_by_bill_ids(uuid[]) IS
  '議案ごとの公開レポート件数（管理者公開 × ユーザー公開）をまとめて返す。法案一覧の回答数バッジ用。';

-- 7. 既存関数のクリーンアップ
DROP FUNCTION IF EXISTS search_bills_for_list(difficulty_level_enum, text, uuid, text, boolean, text, integer, integer);
DROP FUNCTION IF EXISTS search_bills_for_list(difficulty_level_enum, text, uuid, text, boolean, text, integer, integer, uuid);
DROP FUNCTION IF EXISTS search_bills_for_list(difficulty_level_enum, text, uuid, text, boolean, uuid, text, integer, integer);
DROP FUNCTION IF EXISTS count_bills_for_list_facets(difficulty_level_enum, text, uuid, text, boolean);
DROP FUNCTION IF EXISTS count_bills_for_list_facets(difficulty_level_enum, text, uuid, text, boolean, uuid);
DROP FUNCTION IF EXISTS bills_list_rows(difficulty_level_enum, text, boolean);

-- 8. 議案一覧母集合関数 (bills_list_rows)
CREATE OR REPLACE FUNCTION bills_list_rows(
  p_difficulty difficulty_level_enum,
  p_query text default '',
  p_interview_only boolean default false
)
RETURNS TABLE (
  id uuid,
  name text,
  bill_number text,
  status bill_status_enum,
  status_note text,
  submitted_date timestamptz,
  updated_at timestamptz,
  thumbnail_url text,
  thumbnail_key text,
  council_session_id uuid,
  is_review_completed boolean,
  status_order integer,
  content_title text,
  content_summary text,
  has_public_interview boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    b.id, b.name, b.bill_number, b.status, b.status_note,
    b.submitted_date, b.updated_at, b.thumbnail_url, b.thumbnail_key, b.council_session_id,
    b.is_review_completed, b.status_order,
    c.title, c.summary,
    EXISTS (
      SELECT 1 FROM interview_configs ic
      WHERE ic.bill_id = b.id AND ic.status::text = 'public'
    )
  FROM bills b
  JOIN bill_contents c
    ON c.bill_id = b.id AND c.difficulty_level = p_difficulty
  WHERE b.publish_status::text = 'published'
    AND (
      normalize_search_text(p_query) = ''
      OR normalize_search_text(b.name) LIKE '%' || normalize_search_text(p_query) || '%'
      OR normalize_search_text(c.title) LIKE '%' || normalize_search_text(p_query) || '%'
      OR normalize_search_text(c.summary) LIKE '%' || normalize_search_text(p_query) || '%'
      OR EXISTS (
        SELECT 1 FROM bills_tags bt JOIN tags t ON t.id = bt.tag_id
        WHERE bt.bill_id = b.id
          AND normalize_search_text(t.label) LIKE '%' || normalize_search_text(p_query) || '%'
      )
    )
    AND (
      NOT p_interview_only
      OR EXISTS (
        SELECT 1 FROM interview_configs ic2
        WHERE ic2.bill_id = b.id AND ic2.status::text = 'public'
      )
    );
$$;

-- 9. 議案一覧検索関数 (search_bills_for_list)
CREATE OR REPLACE FUNCTION search_bills_for_list(
  p_difficulty difficulty_level_enum,
  p_query text default '',
  p_tag_id uuid default null,
  p_status_group text default 'all',
  p_interview_only boolean default false,
  p_session_id uuid default null,
  p_sort text default 'voices',
  p_limit integer default 30,
  p_offset integer default 0
)
RETURNS TABLE (
  id uuid,
  name text,
  bill_number text,
  status bill_status_enum,
  status_note text,
  submitted_date timestamptz,
  updated_at timestamptz,
  thumbnail_url text,
  thumbnail_key text,
  is_review_completed boolean,
  content_title text,
  content_summary text,
  tags jsonb,
  has_public_interview boolean,
  public_report_count bigint,
  total_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH filtered AS (
    SELECT w.* FROM bills_list_rows(p_difficulty, p_query, p_interview_only) w
    WHERE (
        p_tag_id IS NULL
        OR EXISTS (
          SELECT 1 FROM bills_tags bt
          WHERE bt.bill_id = w.id AND bt.tag_id = p_tag_id
        )
      )
      AND (p_status_group = 'all' OR bill_status_group(w.status) = p_status_group)
      AND (p_session_id IS NULL OR w.council_session_id = p_session_id)
  ),
  counted AS (
    SELECT f.*, COALESCE(rc.report_count, 0) AS public_report_count
    FROM filtered f
    LEFT JOIN count_public_reports_by_bill_ids(
      (SELECT ARRAY_AGG(id) FROM filtered)
    ) rc ON rc.bill_id = f.id
  )
  SELECT
    c.id, c.name, c.bill_number, c.status, c.status_note,
    c.submitted_date, c.updated_at, c.thumbnail_url, c.thumbnail_key,
    c.is_review_completed, c.content_title, c.content_summary,
    COALESCE(
      (
        SELECT jsonb_agg(jsonb_build_object('id', t.id, 'label', t.label)
                         ORDER BY t.label)
        FROM bills_tags bt JOIN tags t ON t.id = bt.tag_id
        WHERE bt.bill_id = c.id
      ),
      '[]'::jsonb
    ),
    c.has_public_interview, c.public_report_count,
    COUNT(*) OVER () AS total_count
  FROM counted c
  ORDER BY
    CASE WHEN p_sort = 'voices' THEN c.public_report_count END DESC NULLS LAST,
    CASE WHEN p_sort = 'new' THEN c.submitted_date END DESC NULLS LAST,
    CASE WHEN p_sort = 'old' THEN c.submitted_date END ASC NULLS LAST,
    CASE WHEN p_sort = 'updated' THEN c.updated_at END DESC NULLS LAST,
    CASE WHEN p_sort = 'status' THEN c.status_order END ASC NULLS LAST,
    c.submitted_date DESC NULLS LAST,
    c.id
  LIMIT p_limit OFFSET p_offset;
$$;

-- 10. 議案一覧ファセット集計関数 (count_bills_for_list_facets)
CREATE OR REPLACE FUNCTION count_bills_for_list_facets(
  p_difficulty difficulty_level_enum,
  p_query text default '',
  p_tag_id uuid default null,
  p_status_group text default 'all',
  p_interview_only boolean default false,
  p_session_id uuid default null
)
RETURNS TABLE (kind text, key text, count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH base AS (
    SELECT
      w.*,
      (p_tag_id IS NULL
        OR EXISTS (
          SELECT 1 FROM bills_tags bt
          WHERE bt.bill_id = w.id AND bt.tag_id = p_tag_id
        )) AS tag_ok,
      (p_status_group = 'all'
        OR bill_status_group(w.status) = p_status_group) AS status_ok,
      (p_session_id IS NULL
        OR w.council_session_id = p_session_id) AS session_ok
    FROM bills_list_rows(p_difficulty, p_query, p_interview_only) w
  )
  SELECT 'status', bill_status_group(b.status), COUNT(*)
  FROM base b WHERE b.tag_ok AND b.session_ok GROUP BY 2
  UNION ALL
  SELECT 'status', 'all', COUNT(*)
  FROM base b WHERE b.tag_ok AND b.session_ok
  UNION ALL
  SELECT 'tag', bt.tag_id::text, COUNT(*)
  FROM base b JOIN bills_tags bt ON bt.bill_id = b.id
  WHERE b.status_ok AND b.session_ok GROUP BY 2
  UNION ALL
  SELECT 'tag', 'all', COUNT(*)
  FROM base b WHERE b.status_ok AND b.session_ok
  UNION ALL
  SELECT 'session', b.council_session_id::text, COUNT(*)
  FROM base b
  WHERE b.status_ok AND b.tag_ok AND b.council_session_id IS NOT NULL
  GROUP BY 2
  UNION ALL
  SELECT 'session', 'all', COUNT(*)
  FROM base b WHERE b.status_ok AND b.tag_ok;
$$;

-- 9. デモレポートの公開フラグ設定（管理者の公開許可をONにする）
UPDATE interview_report SET is_public_by_admin = true WHERE is_public_by_user = true;
