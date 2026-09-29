-- ============================================================
-- みらい議会: 財務・予算・決算関連テーブル定義スクリプト
-- （将来、枚方市の決算カード・予算データを投入する際に実行）
-- ============================================================

-- 1. enum の定義
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fiscal_event_kind_enum') THEN
    CREATE TYPE fiscal_event_kind_enum AS ENUM (
      'initial_budget',
      'supplemental_budget',
      'final_budget',
      'settlement'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fiscal_publication_state_enum') THEN
    CREATE TYPE fiscal_publication_state_enum AS ENUM (
      'draft',
      'review',
      'published',
      'retracted'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fiscal_qa_status_enum') THEN
    CREATE TYPE fiscal_qa_status_enum AS ENUM (
      'unreviewed',
      'verified',
      'flagged'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fiscal_measure_enum') THEN
    CREATE TYPE fiscal_measure_enum AS ENUM (
      'revenue',
      'expenditure'
    );
  END IF;
END $$;

-- 2. 集計範囲テーブル (fiscal_reporting_scopes)
CREATE TABLE IF NOT EXISTS fiscal_reporting_scopes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 初期レコード（一般会計）
INSERT INTO fiscal_reporting_scopes (code, name, description)
VALUES ('general_account', '一般会計', '市の基本的な事業を行う会計')
ON CONFLICT (code) DO NOTHING;

-- 3. 財務イベントテーブル (fiscal_events)
CREATE TABLE IF NOT EXISTS fiscal_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fiscal_year integer NOT NULL,
  kind fiscal_event_kind_enum NOT NULL,
  event_number integer,
  title text NOT NULL,
  description text,
  occurred_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4. 財務分類（款など） (fiscal_classifications)
CREATE TABLE IF NOT EXISTS fiscal_classifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scheme text NOT NULL,
  canonical_key text NOT NULL,
  label text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_fiscal_classifications_scheme_key UNIQUE (scheme, canonical_key)
);

-- 5. 金額セット (fiscal_amount_sets)
CREATE TABLE IF NOT EXISTS fiscal_amount_sets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporting_scope_id uuid NOT NULL REFERENCES fiscal_reporting_scopes(id) ON DELETE RESTRICT,
  amount_set_key text NOT NULL,
  title text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 6. 金額セット改訂 (fiscal_amount_set_revisions)
CREATE TABLE IF NOT EXISTS fiscal_amount_set_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  amount_set_id uuid NOT NULL REFERENCES fiscal_amount_sets(id) ON DELETE CASCADE,
  fiscal_event_id uuid NOT NULL REFERENCES fiscal_events(id) ON DELETE RESTRICT,
  reporting_scope_id uuid NOT NULL REFERENCES fiscal_reporting_scopes(id) ON DELETE RESTRICT,
  fiscal_year integer NOT NULL,
  event_kind fiscal_event_kind_enum NOT NULL,
  revision_number integer NOT NULL DEFAULT 1,
  publication_state fiscal_publication_state_enum NOT NULL DEFAULT 'draft',
  qa_status fiscal_qa_status_enum NOT NULL DEFAULT 'unreviewed',
  effective_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_fiscal_amount_set_revisions UNIQUE (amount_set_id, revision_number)
);

-- 7. 金額行 (fiscal_amounts)
CREATE TABLE IF NOT EXISTS fiscal_amounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  amount_set_id uuid NOT NULL REFERENCES fiscal_amount_sets(id) ON DELETE CASCADE,
  classification_id uuid REFERENCES fiscal_classifications(id) ON DELETE RESTRICT,
  measure fiscal_measure_enum NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 8. 金額改訂 (fiscal_amount_revisions)
CREATE TABLE IF NOT EXISTS fiscal_amount_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  amount_id uuid NOT NULL REFERENCES fiscal_amounts(id) ON DELETE CASCADE,
  revision_number integer NOT NULL DEFAULT 1,
  amount_yen bigint,
  null_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_fiscal_amount_revisions UNIQUE (amount_id, revision_number)
);

-- 9. 出典資料 (fiscal_sources)
CREATE TABLE IF NOT EXISTS fiscal_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  url text,
  published_on date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 10. 金額セット改訂と出典の紐付け (fiscal_amount_set_sources)
CREATE TABLE IF NOT EXISTS fiscal_amount_set_sources (
  amount_set_revision_id uuid NOT NULL REFERENCES fiscal_amount_set_revisions(id) ON DELETE CASCADE,
  fiscal_source_id uuid NOT NULL REFERENCES fiscal_sources(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (amount_set_revision_id, fiscal_source_id)
);

-- RLS 有効化
ALTER TABLE fiscal_reporting_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_amount_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_amount_set_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_amounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_amount_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_amount_set_sources ENABLE ROW LEVEL SECURITY;

