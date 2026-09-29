-- ============================================================
-- 1. interview_sessions の不足カラム追加（既存データ保持）
-- ============================================================
ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS langfuse_session_id TEXT;
ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS rating SMALLINT CHECK (rating >= 1 AND rating <= 5);

-- ============================================================
-- 2. budget_* テーブルの再作成
-- ============================================================
DROP TABLE IF EXISTS budget_initiatives CASCADE;
DROP TABLE IF EXISTS budget_themes CASCADE;
DROP TABLE IF EXISTS budget_overviews CASCADE;

CREATE TABLE budget_overviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  council_session_id uuid NOT NULL REFERENCES council_sessions(id),
  department_name text NOT NULL,
  department_slug text NOT NULL,
  direction text,
  total_budget bigint,
  prev_budget bigint,
  source_url text,
  publish_status text NOT NULL DEFAULT 'draft' CHECK (publish_status IN ('draft', 'published')),
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (council_session_id, department_slug)
);
ALTER TABLE budget_overviews ENABLE ROW LEVEL SECURITY;

CREATE TABLE budget_themes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  overview_id uuid NOT NULL REFERENCES budget_overviews(id) ON DELETE CASCADE,
  title text NOT NULL,
  budget_amount bigint,
  ai_summary text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE budget_themes ENABLE ROW LEVEL SECURITY;

CREATE TABLE budget_initiatives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  theme_id uuid NOT NULL REFERENCES budget_themes(id) ON DELETE CASCADE,
  title text NOT NULL,
  budget_amount bigint,
  badge text CHECK (badge IN ('new', 'expanded', 'continued', null)),
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE budget_initiatives ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 3. bill_discussions の再作成
-- ============================================================
DROP TABLE IF EXISTS bill_discussions CASCADE;

CREATE TABLE bill_discussions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  council_session_id uuid NOT NULL REFERENCES council_sessions(id) ON DELETE CASCADE,
  session_day text NOT NULL,
  questioner_number integer NOT NULL,
  exchange_count integer NOT NULL,
  questioner_name text NOT NULL,
  questioner_role text,
  question_raw text NOT NULL,
  question_summary text,
  answerer_name text NOT NULL,
  answerer_role text,
  answer_raw text NOT NULL,
  answer_summary text,
  source_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bill_id, session_day, questioner_number, exchange_count)
);
ALTER TABLE bill_discussions ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_bill_discussions_bill_id ON bill_discussions(bill_id);
CREATE INDEX idx_bill_discussions_session_id ON bill_discussions(council_session_id);

-- ============================================================
-- 4. committee_meetings & committee_meeting_topics の再作成
-- ============================================================
DROP TABLE IF EXISTS committee_meeting_topics CASCADE;
DROP TABLE IF EXISTS committee_meetings CASCADE;

CREATE TABLE committee_meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  committee_name text NOT NULL,
  committee_slug text NOT NULL,
  committee_type text NOT NULL DEFAULT 'standing'
    CHECK (committee_type IN ('standing', 'special', 'budget', 'audit', 'management')),
  meeting_date date NOT NULL,
  title text NOT NULL,
  source_document_id integer NOT NULL UNIQUE,
  source_url text NOT NULL,
  summary text,
  speeches jsonb NOT NULL DEFAULT '[]'::jsonb,
  raw_text text NOT NULL,
  publish_status text NOT NULL DEFAULT 'draft'
    CHECK (publish_status IN ('draft', 'published')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE committee_meetings ENABLE ROW LEVEL SECURITY;
CREATE INDEX committee_meetings_slug_date_idx ON committee_meetings(committee_slug, meeting_date DESC);

CREATE TABLE committee_meeting_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES committee_meetings(id) ON DELETE CASCADE,
  topic_order integer NOT NULL,
  title text NOT NULL,
  summary text,
  discussion_summary text,
  start_voice_no integer,
  end_voice_no integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (meeting_id, topic_order)
);
ALTER TABLE committee_meeting_topics ENABLE ROW LEVEL SECURITY;
CREATE INDEX committee_meeting_topics_meeting_id_idx ON committee_meeting_topics(meeting_id);

-- ============================================================
-- 5. general_question_overviews の再作成
-- ============================================================
DROP TABLE IF EXISTS general_question_overviews CASCADE;

CREATE TABLE general_question_overviews (
  council_session_id uuid PRIMARY KEY REFERENCES council_sessions(id) ON DELETE CASCADE,
  lines text[] NOT NULL,
  theme_lines jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE general_question_overviews ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. chat_usage_events の再作成
-- ============================================================
DROP TABLE IF EXISTS chat_usage_events CASCADE;

CREATE TABLE chat_usage_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  session_id text,
  prompt_name text,
  model text NOT NULL,
  input_tokens integer NOT NULL DEFAULT 0,
  output_tokens integer NOT NULL DEFAULT 0,
  total_tokens integer NOT NULL DEFAULT 0,
  cost_usd numeric(12, 6) NOT NULL DEFAULT 0,
  metadata jsonb,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX chat_usage_events_user_id_occurred_at_idx ON chat_usage_events(user_id, occurred_at);
ALTER TABLE chat_usage_events ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 7. preview_tokens の再作成
-- ============================================================
DROP TABLE IF EXISTS preview_tokens CASCADE;

CREATE TABLE preview_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by text
);
CREATE INDEX idx_preview_tokens_token ON preview_tokens(token);
CREATE INDEX idx_preview_tokens_bill_id ON preview_tokens(bill_id);
CREATE INDEX idx_preview_tokens_expires_at ON preview_tokens(expires_at);
ALTER TABLE preview_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 8. expert_registrations の再作成
-- ============================================================
DROP TABLE IF EXISTS expert_registrations CASCADE;

CREATE TABLE expert_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  affiliation text NOT NULL,
  email text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_expert_registrations_user_id ON expert_registrations(user_id);
CREATE UNIQUE INDEX idx_expert_registrations_email ON expert_registrations(email);
ALTER TABLE expert_registrations ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 9. report_reactions の再作成
-- ============================================================
DROP TABLE IF EXISTS report_reactions CASCADE;

CREATE TABLE report_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_report_id uuid NOT NULL REFERENCES interview_report(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  reaction_type text NOT NULL CHECK (reaction_type IN ('helpful', 'hmm')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (interview_report_id, user_id)
);
ALTER TABLE report_reactions ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_report_reactions_report_id ON report_reactions(interview_report_id);
CREATE INDEX idx_report_reactions_user_id ON report_reactions(user_id);

-- ============================================================
-- 10. topic_analysis_* の再作成
-- ============================================================
DROP TABLE IF EXISTS topic_analysis_classifications CASCADE;
DROP TABLE IF EXISTS topic_analysis_topics CASCADE;
DROP TABLE IF EXISTS topic_analysis_versions CASCADE;

CREATE TABLE topic_analysis_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  version integer NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','running','completed','failed')),
  summary_md text,
  intermediate_results jsonb,
  error_message text,
  current_step text,
  started_at timestamptz,
  completed_at timestamptz,
  phase_data jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(bill_id, version)
);
ALTER TABLE topic_analysis_versions ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_topic_analysis_versions_bill_id ON topic_analysis_versions(bill_id);

CREATE TABLE topic_analysis_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id uuid NOT NULL REFERENCES topic_analysis_versions(id) ON DELETE CASCADE,
  name text NOT NULL,
  description_md text NOT NULL,
  representative_opinions jsonb NOT NULL DEFAULT '[]',
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE topic_analysis_topics ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_topic_analysis_topics_version_id ON topic_analysis_topics(version_id);

CREATE TABLE topic_analysis_classifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version_id uuid NOT NULL REFERENCES topic_analysis_versions(id) ON DELETE CASCADE,
  interview_report_id uuid NOT NULL REFERENCES interview_report(id) ON DELETE CASCADE,
  topic_id uuid NOT NULL REFERENCES topic_analysis_topics(id) ON DELETE CASCADE,
  opinion_index integer NOT NULL,
  UNIQUE(version_id, interview_report_id, topic_id, opinion_index)
);
ALTER TABLE topic_analysis_classifications ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_topic_analysis_classifications_version_id ON topic_analysis_classifications(version_id);
CREATE INDEX idx_topic_analysis_classifications_topic_id ON topic_analysis_classifications(topic_id);

-- ============================================================
-- 11. press_conferences & items & turns の再作成
-- ============================================================
DROP TABLE IF EXISTS press_conference_turns CASCADE;
DROP TABLE IF EXISTS press_conference_items CASCADE;
DROP TABLE IF EXISTS press_conferences CASCADE;

CREATE TABLE press_conferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  held_at date NOT NULL,
  youtube_url text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'structuring', 'review', 'published', 'error')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE press_conferences ENABLE ROW LEVEL SECURITY;
CREATE INDEX ON press_conferences (slug);
CREATE INDEX ON press_conferences (held_at DESC);
CREATE INDEX ON press_conferences (status);

CREATE TABLE press_conference_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  press_conference_id uuid NOT NULL REFERENCES press_conferences(id) ON DELETE CASCADE,
  item_type text NOT NULL CHECK (item_type IN ('announcement', 'qa')),
  order_index int NOT NULL,
  title text NOT NULL,
  summary text,
  material_url text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE press_conference_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX ON press_conference_items (press_conference_id, order_index);

CREATE TABLE press_conference_turns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  press_conference_item_id uuid NOT NULL REFERENCES press_conference_items(id) ON DELETE CASCADE,
  speaker text NOT NULL CHECK (speaker IN ('mayor', 'reporter')),
  speaker_name text,
  content text NOT NULL,
  order_index int NOT NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE press_conference_turns ENABLE ROW LEVEL SECURITY;
CREATE INDEX ON press_conference_turns (press_conference_item_id, order_index);

-- ============================================================
-- 12. jimu_jigyo_* テーブル & ビュー & 関数の再作成
-- ============================================================
DROP VIEW IF EXISTS jimu_jigyo_budget_timeline CASCADE;
DROP VIEW IF EXISTS jimu_jigyo_latest CASCADE;
DROP FUNCTION IF EXISTS get_jimu_jigyo_statistics CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_kpi_results CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_kpi_targets CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_kpi_items CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_fiscal_years CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_matching_logs CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_import_logs CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_items CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_kpi_types CASCADE;
DROP TABLE IF EXISTS jimu_jigyo_bureaus CASCADE;

-- 1. 部局マスタ
CREATE TABLE jimu_jigyo_bureaus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bureau_code TEXT NOT NULL UNIQUE,
  bureau_name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE jimu_jigyo_bureaus ENABLE ROW LEVEL SECURITY;

-- 2. KPI種別マスタ
CREATE TABLE jimu_jigyo_kpi_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_code TEXT NOT NULL UNIQUE,
  type_name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE jimu_jigyo_kpi_types ENABLE ROW LEVEL SECURITY;

-- 3. 事務事業マスター（事業単位）
CREATE TABLE jimu_jigyo_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bureau_code TEXT NOT NULL REFERENCES jimu_jigyo_bureaus(bureau_code) ON DELETE RESTRICT,
  bureau_name TEXT NOT NULL,
  item_name TEXT NOT NULL,
  item_code TEXT,
  slug TEXT,
  raw_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (bureau_code, item_name)
);
ALTER TABLE jimu_jigyo_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jimu_jigyo_items_bureau ON jimu_jigyo_items(bureau_code);
CREATE INDEX idx_jimu_jigyo_items_name ON jimu_jigyo_items(item_name);
CREATE INDEX idx_jimu_jigyo_items_slug ON jimu_jigyo_items(slug);

-- 4. 年度別実績データ
CREATE TABLE jimu_jigyo_fiscal_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES jimu_jigyo_items(id) ON DELETE CASCADE,
  fiscal_year INTEGER NOT NULL,
  expenditure_amount BIGINT,
  specific_revenue BIGINT,
  general_revenue BIGINT,
  staff_members INTEGER,
  summary TEXT,
  current_status TEXT,
  problem_issue TEXT,
  progress_plan TEXT,
  analysis_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (item_id, fiscal_year)
);
ALTER TABLE jimu_jigyo_fiscal_years ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jimu_jigyo_fy_item_year ON jimu_jigyo_fiscal_years(item_id, fiscal_year);
CREATE INDEX idx_jimu_jigyo_fy_created ON jimu_jigyo_fiscal_years(created_at DESC);

-- 5. KPI項目定義
CREATE TABLE jimu_jigyo_kpi_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES jimu_jigyo_items(id) ON DELETE CASCADE,
  kpi_type_code TEXT NOT NULL REFERENCES jimu_jigyo_kpi_types(type_code) ON DELETE RESTRICT,
  kpi_name TEXT NOT NULL,
  target_direction TEXT,
  unit TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (item_id, kpi_name)
);
ALTER TABLE jimu_jigyo_kpi_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jimu_jigyo_kpi_items_item ON jimu_jigyo_kpi_items(item_id);

-- 6. KPI目標値
CREATE TABLE jimu_jigyo_kpi_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kpi_item_id UUID NOT NULL REFERENCES jimu_jigyo_kpi_items(id) ON DELETE CASCADE,
  target_year INTEGER NOT NULL,
  target_value TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (kpi_item_id, target_year)
);
ALTER TABLE jimu_jigyo_kpi_targets ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jimu_jigyo_kpi_targets_item ON jimu_jigyo_kpi_targets(kpi_item_id);

-- 7. KPI年度別実績値
CREATE TABLE jimu_jigyo_kpi_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kpi_item_id UUID NOT NULL REFERENCES jimu_jigyo_kpi_items(id) ON DELETE CASCADE,
  fiscal_year INTEGER NOT NULL,
  target_value TEXT,
  result_value TEXT,
  achievement_rate TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (kpi_item_id, fiscal_year)
);
ALTER TABLE jimu_jigyo_kpi_results ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jimu_jigyo_kpi_results_item_year ON jimu_jigyo_kpi_results(kpi_item_id, fiscal_year);
CREATE INDEX idx_jimu_jigyo_kpi_results_created ON jimu_jigyo_kpi_results(created_at DESC);

-- 8. インポート管理ログ
CREATE TABLE jimu_jigyo_import_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL,
  file_name TEXT NOT NULL,
  source_url TEXT,
  fiscal_year INTEGER,
  status TEXT NOT NULL DEFAULT 'pending'
    CONSTRAINT status_valid CHECK (status IN ('pending', 'completed', 'failed', 'completed_with_errors')),
  total_records INTEGER NOT NULL DEFAULT 0,
  imported_records INTEGER NOT NULL DEFAULT 0,
  error_details JSONB,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE jimu_jigyo_import_logs ENABLE ROW LEVEL SECURITY;

-- 9. 名寄せ・突合ログ
CREATE TABLE jimu_jigyo_matching_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  import_log_id UUID NOT NULL REFERENCES jimu_jigyo_import_logs(id) ON DELETE CASCADE,
  item_id UUID REFERENCES jimu_jigyo_items(id) ON DELETE SET NULL,
  original_bureau_name TEXT NOT NULL,
  original_item_name TEXT NOT NULL,
  matched_bureau_code TEXT,
  confidence_score NUMERIC(3, 2),
  is_manual_override BOOLEAN NOT NULL DEFAULT false,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE jimu_jigyo_matching_logs ENABLE ROW LEVEL SECURITY;

-- 10. ビュー: 最新年度データとKPI集約
CREATE OR REPLACE VIEW jimu_jigyo_latest AS
WITH latest_fy AS (
  SELECT DISTINCT ON (item_id)
    item_id,
    fiscal_year,
    expenditure_amount,
    specific_revenue,
    general_revenue,
    staff_members,
    summary,
    current_status,
    problem_issue,
    progress_plan,
    analysis_json
  FROM jimu_jigyo_fiscal_years
  ORDER BY item_id, fiscal_year DESC
),
available_years_agg AS (
  SELECT
    item_id,
    ARRAY_AGG(fiscal_year ORDER BY fiscal_year ASC) AS available_years
  FROM jimu_jigyo_fiscal_years
  GROUP BY item_id
)
SELECT
  jj.id,
  jj.bureau_code,
  jj.bureau_name,
  jj.item_name,
  jj.item_code,
  jj.slug,
  jj.raw_data,
  lfy.fiscal_year AS latest_fiscal_year,
  lfy.expenditure_amount,
  lfy.specific_revenue,
  lfy.general_revenue,
  lfy.staff_members,
  lfy.summary,
  lfy.current_status,
  lfy.problem_issue,
  lfy.progress_plan,
  lfy.analysis_json,
  COALESCE(aya.available_years, ARRAY[]::integer[]) AS available_years,
  jj.created_at,
  jj.updated_at
FROM jimu_jigyo_items jj
LEFT JOIN latest_fy lfy ON jj.id = lfy.item_id
LEFT JOIN available_years_agg aya ON jj.id = aya.item_id;

-- 11. ビュー: 決算推移（前年比計算）
CREATE OR REPLACE VIEW jimu_jigyo_budget_timeline AS
SELECT
  jj.item_name,
  jj.bureau_name,
  fy.fiscal_year,
  fy.expenditure_amount,
  fy.specific_revenue,
  fy.general_revenue,
  LAG(fy.expenditure_amount) OVER (
    PARTITION BY fy.item_id
    ORDER BY fy.fiscal_year
  ) AS prev_year_amount,
  ROUND(
    ((fy.expenditure_amount - LAG(fy.expenditure_amount) OVER (
      PARTITION BY fy.item_id
      ORDER BY fy.fiscal_year
    )) / NULLIF(LAG(fy.expenditure_amount) OVER (
      PARTITION BY fy.item_id
      ORDER BY fy.fiscal_year
    ), 0) * 100)::numeric, 1
  ) AS change_rate_percent
FROM jimu_jigyo_items jj
JOIN jimu_jigyo_fiscal_years fy ON jj.id = fy.item_id
ORDER BY jj.item_name, fy.fiscal_year;

-- 12. 関数: 年度別統計の集約
CREATE OR REPLACE FUNCTION get_jimu_jigyo_statistics(
  target_fiscal_year INTEGER
)
RETURNS TABLE (
  fiscal_year INTEGER,
  total_items BIGINT,
  total_budget BIGINT,
  avg_achievement_rate NUMERIC,
  bureau_breakdown JSONB
) AS $$
BEGIN
  RETURN QUERY
  WITH base AS (
    SELECT
      jj.id,
      jj.bureau_code,
      jj.bureau_name,
      fy.expenditure_amount,
      CASE
        WHEN kr.achievement_rate ~ '^\d+(\.\d+)?%?$'
        THEN REPLACE(kr.achievement_rate, '%', '')::numeric
        ELSE NULL
      END AS achievement_rate_num
    FROM jimu_jigyo_items jj
    JOIN jimu_jigyo_fiscal_years fy ON jj.id = fy.item_id
      AND fy.fiscal_year = target_fiscal_year
    LEFT JOIN jimu_jigyo_kpi_items ki ON jj.id = ki.item_id
    LEFT JOIN jimu_jigyo_kpi_results kr ON ki.id = kr.kpi_item_id
      AND kr.fiscal_year = target_fiscal_year
  ),
  bureau_agg AS (
    SELECT
      bureau_code,
      bureau_name,
      COUNT(DISTINCT id)::BIGINT AS item_count,
      SUM(DISTINCT expenditure_amount)::BIGINT AS total_budget
    FROM base
    GROUP BY bureau_code, bureau_name
  )
  SELECT
    target_fiscal_year AS fiscal_year,
    COUNT(DISTINCT b.id)::BIGINT AS total_items,
    SUM(DISTINCT b.expenditure_amount)::BIGINT AS total_budget,
    ROUND(AVG(b.achievement_rate_num), 1) AS avg_achievement_rate,
    (SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
      'bureau_code', ba.bureau_code,
      'bureau_name', ba.bureau_name,
      'item_count', ba.item_count,
      'total_budget', ba.total_budget
    )) FROM bureau_agg ba) AS bureau_breakdown
  FROM base b;
END;
$$ LANGUAGE plpgsql STABLE;
