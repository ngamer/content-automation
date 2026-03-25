-- ============================================================================
-- Content Orchestration Knowledge Base — Databricks CREATE TABLE Statements
-- Schema v2.1 | Generated: March 21, 2026
-- Target: Databricks Unity Catalog with Delta Lake
-- Instructions: Run in Databricks SQL Editor in the order listed below
--
-- CHANGES FROM v2.0:
--   [OPT-1]  step5_refresh.runs split into runs header + 5 gate detail tables
--   [OPT-2]  step5_creation.runs split into runs header + 3 detail tables
--   [OPT-3]  core.article_production_history added — lightweight ledger for
--            pre-publish baselines and 90-day review lookups
--   [OPT-4]  orchestration.artifacts extended with confluence_page_id,
--            sharepoint_item_id, onedrive_path for multi-environment resolution
--   [OPT-5]  intelligence.* tables gain is_current + valid_from/valid_to for
--            SCD-style staleness tracking; no silent accumulation
--   [OPT-6]  orchestration.known_issues added — persists KI-01, KI-02 and
--            future known gaps with blocking status and resolution tracking
--   [OPT-7]  handoff_blocks tables gain consumption_status enum, consumed_at,
--            consuming_agent_id — prevents race conditions in multi-agent env
--   [OPT-8]  intelligence.* tables: explicit FK comments + join path to
--            step3_audit.* documented; processing contract clarified
-- ============================================================================

-- ============================================================================
-- STEP 0: CREATE CATALOG AND SCHEMAS
-- ============================================================================

CREATE CATALOG IF NOT EXISTS risepoint_content;

CREATE SCHEMA IF NOT EXISTS risepoint_content.core;
CREATE SCHEMA IF NOT EXISTS risepoint_content.intelligence;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step1_cluster;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step2_gap;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step3_audit;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step4_ideation;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step5_refresh;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step5_creation;
CREATE SCHEMA IF NOT EXISTS risepoint_content.step6_swa;
CREATE SCHEMA IF NOT EXISTS risepoint_content.orchestration;
CREATE SCHEMA IF NOT EXISTS risepoint_content.ai_visibility;

-- ============================================================================
-- SCHEMA: core (Reference Data)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.core.clients (
  client_id   STRING NOT NULL COMMENT 'Primary key. e.g., fit, astate, bgsu',
  client_name STRING COMMENT 'Full client name',
  created_at  TIMESTAMP DEFAULT current_timestamp(),
  updated_at  TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_clients PRIMARY KEY (client_id)
) USING DELTA
COMMENT 'Reference table for all Risepoint clients';

CREATE TABLE IF NOT EXISTS risepoint_content.core.programs (
  program_id             STRING  NOT NULL COMMENT 'Primary key. e.g., fit_online_mba',
  client_id              STRING  NOT NULL COMMENT 'FK to core.clients',
  program_name           STRING  COMMENT 'Full program name',
  domain                 STRING  COMMENT 'e.g., online.fit.edu',
  subdomain              STRING  COMMENT 'e.g., online',
  program_url            STRING  COMMENT 'Landing page URL — used as seed for Module 0 competitive analysis',
  focus_area             STRING  COMMENT 'e.g., Online degree programs, MBA',
  target_audience        STRING  COMMENT 'e.g., Prospective graduate students',
  program_format         STRING  COMMENT 'online, hybrid, on-campus',
  key_differentiators    STRING  COMMENT 'JSON array from Phase 0D program intelligence',
  curriculum_components  STRING  COMMENT 'JSON array of course names',
  gmat_required          BOOLEAN COMMENT 'NULL if unknown',
  created_at             TIMESTAMP DEFAULT current_timestamp(),
  updated_at             TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_programs PRIMARY KEY (program_id)
) USING DELTA
COMMENT 'Reference table for all programs across clients';

CREATE TABLE IF NOT EXISTS risepoint_content.core.articles (
  article_id           STRING  NOT NULL COMMENT 'Primary key (hash of URL)',
  program_id           STRING  COMMENT 'FK to core.programs',
  article_url          STRING  COMMENT 'Full URL',
  article_title        STRING  COMMENT 'Page title',
  content_type         STRING  COMMENT 'program overview, career guide, how-to, comparison, faq, informational',
  search_intent        STRING  COMMENT 'Informational, Navigational, Commercial, Transactional',
  word_count           INT     COMMENT 'Current word count',
  publish_date         DATE    COMMENT 'Original publication date',
  last_modified_date   DATE    COMMENT 'Last modified date',
  last_refresh_date    DATE    COMMENT 'Most recent refresh completion date',
  status               STRING  COMMENT 'active = published, retired = removed, redirect = URL redirected, draft = not yet published, planned = in content calendar',
  redirect_target      STRING  COMMENT 'URL if status = redirect',
  http_status          INT     COMMENT 'Last checked HTTP status code',
  content_age_category STRING  COMMENT 'Fresh (0-6mo), Current (6-12mo), Aging (12-24mo), Aging-Extended (24-36mo), Stale (36+mo)',
  subheading_count     INT,
  has_faq_section      BOOLEAN,
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  updated_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_articles PRIMARY KEY (article_id)
) USING DELTA
COMMENT 'All published and draft articles across all programs';

-- [OPT-3] Lightweight production history ledger.
-- Replaces full-scan joins on step5_refresh.runs / step5_creation.runs for
-- pre-publish baseline lookups (90-Day Review Agent) and per-article history.
-- One row per completed production run. append-only; never updated.
CREATE TABLE IF NOT EXISTS risepoint_content.core.article_production_history (
  history_id      STRING NOT NULL COMMENT 'Primary key (UUID)',
  article_id      STRING NOT NULL COMMENT 'FK to core.articles',
  program_id      STRING COMMENT 'FK to core.programs — denormalized for query convenience',
  run_type        STRING NOT NULL COMMENT 'refresh / creation',
  source_run_id   STRING NOT NULL COMMENT 'FK to step5_refresh.runs or step5_creation.runs',
  completed_date  DATE   NOT NULL,
  gate4_score     DOUBLE COMMENT 'SEO Quality Score at completion',
  swa_score       DOUBLE COMMENT 'SWA score at completion (NULL if not run)',
  word_count      INT    COMMENT 'Word count at completion',
  flesch_score    DOUBLE COMMENT 'FRE at completion',
  primary_keyword STRING COMMENT 'Targeted keyword for this production run',
  gsc_position_pre  DOUBLE COMMENT 'GSC avg position immediately before run (pre-publish baseline)',
  gsc_clicks_pre    INT    COMMENT 'GSC 90-day clicks before run (pre-publish baseline)',
  created_at      TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_article_history PRIMARY KEY (history_id)
) USING DELTA
COMMENT '[OPT-3] Append-only ledger of every completed production run per article. Source of truth for 90-Day Review Agent pre-publish baseline comparisons. Fast point lookups — no full-scan needed.';

CREATE TABLE IF NOT EXISTS risepoint_content.core.draft_content (
  draft_id                   STRING NOT NULL COMMENT 'Primary key',
  program_id                 STRING COMMENT 'FK to core.programs',
  working_title              STRING,
  description                STRING COMMENT '2-3 sentence description',
  target_publication_date    DATE,
  primary_category           STRING COMMENT 'Core/Program, Curriculum, Career/Outcomes, Professional Dev, Other',
  cluster_impact_assessment  STRING COMMENT 'How this draft strengthens the cluster',
  publishing_priority        INT    COMMENT 'Recommended sequence position',
  fit_rating                 STRING COMMENT 'From CCA analysis',
  status                     STRING COMMENT 'planned, in_progress, published',
  created_at                 TIMESTAMP DEFAULT current_timestamp(),
  updated_at                 TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_draft_content PRIMARY KEY (draft_id)
) USING DELTA
COMMENT 'Planned/draft articles not yet published. Moves to core.articles when published.';

-- ============================================================================
-- SCHEMA: intelligence (Raw API Data from n8n)
--
-- [OPT-5] STALENESS DESIGN: All tables use is_current + valid_from/valid_to.
-- On each pull, the maintenance skill SETSs is_current = false on all prior
-- rows for the same target, then INSERTs new rows with is_current = true.
-- This prevents silent accumulation and makes "current snapshot" queries
-- a simple WHERE is_current = true.
--
-- [OPT-8] PROCESSING CONTRACT: These tables hold raw API responses.
-- The step3_audit.* and step5_*.* tables hold processed/interpreted output.
-- Intelligence tables are populated by: (a) the n8n maintenance skill
-- on its weekly/monthly schedule, and (b) individual workflow step agents
-- when they execute live Ahrefs/GSC calls. Agents reading from step3_audit.*
-- do NOT need to re-query intelligence.*; all required data is already
-- processed and stored in the audit tables.
-- Join path: intelligence.ahrefs_organic_keywords → step3_audit.keyword_rankings
-- via keyword (string match) + target_url/article_url + pull_date proximity.
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.ahrefs_organic_keywords (
  id            STRING NOT NULL,
  target_url    STRING COMMENT 'URL or domain queried',
  target_mode   STRING COMMENT 'exact, subdomains, prefix',
  keyword       STRING,
  best_position INT    COMMENT 'Ahrefs top_keyword_best_position field name',
  volume        INT,
  sum_traffic   DOUBLE COMMENT 'Ahrefs sum_traffic field name — use this not traffic',
  keyword_difficulty DOUBLE,
  serp_features STRING COMMENT 'JSON array',
  country       STRING,
  pull_date     DATE,
  is_current    BOOLEAN DEFAULT true  COMMENT '[OPT-5] true = most recent pull for this target_url',
  valid_from    DATE    COMMENT '[OPT-5] Date this row became current',
  valid_to      DATE    COMMENT '[OPT-5] Date superseded; NULL if is_current = true',
  created_at    TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ahrefs_organic PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw Ahrefs site-explorer-organic-keywords. Query WHERE is_current = true for latest snapshot.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.ahrefs_serp_overview (
  id            STRING NOT NULL,
  keyword       STRING COMMENT 'Queried keyword',
  position      INT    COMMENT 'SERP position',
  url           STRING COMMENT 'Ranking URL',
  title         STRING COMMENT 'Page title',
  domain_rating INT,
  backlinks     INT,
  traffic       INT,
  keywords      INT    COMMENT 'Total keywords this page ranks for',
  country       STRING,
  pull_date     DATE,
  is_current    BOOLEAN DEFAULT true  COMMENT '[OPT-5] true = most recent pull for this keyword',
  valid_from    DATE,
  valid_to      DATE    COMMENT 'NULL if is_current = true',
  created_at    TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ahrefs_serp PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw Ahrefs serp-overview. Query WHERE is_current = true for latest snapshot.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.ahrefs_related_terms (
  id               STRING NOT NULL,
  seed_keyword     STRING,
  keyword          STRING,
  volume           INT,
  difficulty       DOUBLE,
  traffic_potential INT,
  search_intent    STRING,
  country          STRING,
  pull_date        DATE,
  is_current       BOOLEAN DEFAULT true,
  valid_from       DATE,
  valid_to         DATE,
  created_at       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ahrefs_related PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw Ahrefs keywords-explorer-related-terms. Query WHERE is_current = true.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.ahrefs_matching_terms (
  id                STRING NOT NULL,
  seed_keyword      STRING,
  keyword           STRING,
  volume            INT,
  difficulty        DOUBLE,
  traffic_potential INT,
  country           STRING,
  pull_date         DATE,
  is_current        BOOLEAN DEFAULT true,
  valid_from        DATE,
  valid_to          DATE,
  created_at        TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ahrefs_matching PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw Ahrefs keywords-explorer-matching-terms. Query WHERE is_current = true.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.ahrefs_search_suggestions (
  id           STRING NOT NULL,
  seed_keyword STRING,
  keyword      STRING,
  volume       INT,
  difficulty   DOUBLE,
  country      STRING,
  pull_date    DATE,
  is_current   BOOLEAN DEFAULT true,
  valid_from   DATE,
  valid_to     DATE,
  created_at   TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ahrefs_suggestions PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw Ahrefs keywords-explorer-search-suggestions. Query WHERE is_current = true.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.gsc_page_performance (
  id                  STRING  NOT NULL,
  site_url            STRING  COMMENT 'GSC property',
  page_url            STRING  COMMENT 'Article URL',
  clicks              INT     COMMENT 'Actual clicks — ground truth, not Ahrefs estimate',
  impressions         INT,
  ctr                 DOUBLE  COMMENT 'Click-through rate',
  avg_position        DOUBLE,
  date_range_start    DATE,
  date_range_end      DATE,
  monthly_clicks      DOUBLE  COMMENT 'Calculated: clicks / months in range',
  is_zero_click       BOOLEAN COMMENT 'impressions > 0 AND clicks = 0',
  pull_date           DATE,
  is_current          BOOLEAN DEFAULT true  COMMENT '[OPT-5] true = most recent pull for this page_url',
  valid_from          DATE,
  valid_to            DATE    COMMENT 'NULL if is_current = true',
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gsc_performance PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw GSC search analytics per page. GSC is ground truth for traffic — Ahrefs can overestimate 3-15x. Query WHERE is_current = true for latest.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.ga4_page_metrics (
  id                    STRING NOT NULL,
  property_id           STRING COMMENT 'GA4 property',
  page_path             STRING,
  sessions              INT,
  engaged_sessions      INT,
  avg_engagement_time   DOUBLE COMMENT 'Seconds',
  bounce_rate           DOUBLE,
  conversions           INT,
  date_range_start      DATE,
  date_range_end        DATE,
  pull_date             DATE,
  is_current            BOOLEAN DEFAULT true,
  valid_from            DATE,
  valid_to              DATE,
  created_at            TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ga4_metrics PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Raw GA4 engagement metrics per page. Query WHERE is_current = true.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.serp_features (
  id                  STRING NOT NULL,
  keyword             STRING,
  feature_type        STRING COMMENT 'featured_snippet, paa, ai_overview, knowledge_panel, video, etc.',
  current_holder_url  STRING,
  program_id          STRING COMMENT 'FK to core.programs',
  pull_date           DATE,
  is_current          BOOLEAN DEFAULT true,
  valid_from          DATE,
  valid_to            DATE,
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_serp_features PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] SERP feature tracking per keyword. Query WHERE is_current = true.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.paa_questions (
  id                     STRING  NOT NULL,
  keyword                STRING  COMMENT 'Source keyword',
  question               STRING  COMMENT 'People Also Ask question text',
  program_id             STRING,
  is_covered             BOOLEAN COMMENT 'Do we answer this question?',
  covered_by_article_id  STRING  COMMENT 'FK to core.articles',
  pull_date              DATE,
  is_current             BOOLEAN DEFAULT true,
  valid_from             DATE,
  valid_to               DATE,
  created_at             TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_paa PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] People Also Ask questions per keyword. Query WHERE is_current = true.';

CREATE TABLE IF NOT EXISTS risepoint_content.intelligence.competitor_content (
  id                  STRING NOT NULL,
  competitor_url      STRING,
  competitor_domain   STRING,
  target_keyword      STRING COMMENT 'What keyword this ranks for',
  serp_position       INT,
  word_count          INT    COMMENT 'Body word count from DataForSEO parsing',
  domain_rating       INT,
  backlinks           INT,
  traffic             INT,
  flesch_score        DOUBLE COMMENT 'FRE calculator result',
  h2_structure        STRING COMMENT 'JSON array of H2 headings',
  strengths           STRING,
  weaknesses          STRING,
  program_id          STRING COMMENT 'Which of our programs this competes with',
  pull_date           DATE,
  is_current          BOOLEAN DEFAULT true,
  valid_from          DATE,
  valid_to            DATE,
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_competitor_content PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-5] Competitor article analysis from DataForSEO and Ahrefs. Query WHERE is_current = true.';

-- ============================================================================
-- SCHEMA: step1_cluster (CCA1 Outputs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step1_cluster.runs (
  run_id                  STRING  NOT NULL,
  program_id              STRING,
  run_date                DATE,
  run_mode                STRING  COMMENT 'Workflow / Standalone',
  input_mode              STRING  COMMENT 'Mode A (widget) / Mode B (directory) / Mode C (bulk)',
  multi_program           BOOLEAN,
  widget_element_id       STRING  COMMENT 'HTML element identifier (Mode A)',
  widget_article_count    INT     COMMENT 'Articles visible in widget (Mode A)',
  total_inventory_count   INT     COMMENT 'Total published articles for program',
  visibility_gap          INT     COMMENT 'total - widget count (Mode A)',
  prompt_version          STRING,
  config_version          STRING,
  gate_1_result           STRING  COMMENT 'Proceed / Close',
  artifact_path           STRING,
  created_at              TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_cluster_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT 'One row per CCA execution. CCA runs ONCE per program assessment.';

CREATE TABLE IF NOT EXISTS risepoint_content.step1_cluster.clusters (
  cluster_id             STRING NOT NULL,
  run_id                 STRING COMMENT 'FK to runs',
  program_id             STRING,
  cluster_name           STRING,
  cohesion_score         DOUBLE,
  article_count_published INT,
  article_count_draft    INT,
  status                 STRING COMMENT 'healthy, weak, saturated, missing',
  created_at             TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_clusters PRIMARY KEY (cluster_id)
) USING DELTA
COMMENT 'Topic clusters identified per CCA run';

CREATE TABLE IF NOT EXISTS risepoint_content.step1_cluster.article_assignments (
  id                        STRING  NOT NULL,
  cluster_id                STRING  COMMENT 'FK to clusters',
  article_id                STRING  COMMENT 'FK to core.articles (NULL for drafts)',
  draft_id                  STRING  COMMENT 'FK to core.draft_content (NULL for published)',
  category                  STRING  COMMENT 'Core/Program, Curriculum, Career/Outcomes, Professional Dev, Other',
  fit_rating                STRING  COMMENT 'Strong, Good, Moderate, Poor',
  is_outlier                BOOLEAN,
  outlier_reasoning         STRING,
  is_orphan                 BOOLEAN COMMENT 'No navigation path',
  is_cross_program          BOOLEAN,
  misclassification_target  STRING  COMMENT 'Recommended program if misclassified',
  created_at                TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_article_assignments PRIMARY KEY (id)
) USING DELTA
COMMENT 'Per-article cluster assignment with fit ratings and flags';

CREATE TABLE IF NOT EXISTS risepoint_content.step1_cluster.linking_audit (
  id                 STRING NOT NULL,
  run_id             STRING COMMENT 'FK to runs',
  source_article_id  STRING COMMENT 'FK to core.articles',
  target_article_id  STRING COMMENT 'FK to core.articles',
  link_type          STRING COMMENT 'existing, recommended, missing_bidirectional, bridge_opportunity',
  is_bidirectional   BOOLEAN,
  priority           STRING COMMENT 'high, medium, low',
  recommendation     STRING,
  created_at         TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_linking_audit PRIMARY KEY (id)
) USING DELTA
COMMENT 'Internal linking audit recommendations from CCA';

-- [OPT-7] handoff_blocks: consumption_status replaces simple boolean.
-- Prevents race conditions where two agents consume the same handoff,
-- or a failed agent leaves a handoff permanently marked consumed.
CREATE TABLE IF NOT EXISTS risepoint_content.step1_cluster.handoff_blocks (
  id                   STRING NOT NULL,
  run_id               STRING COMMENT 'FK to runs',
  connection_id        STRING COMMENT 'C1, C2, C5',
  target_step          STRING COMMENT 'GAP17, CCW68_Phase0D, ARID14',
  handoff_content      STRING COMMENT 'Full pre-formatted block text',
  consumption_status   STRING DEFAULT 'pending'   COMMENT '[OPT-7] pending / in_progress / consumed / failed',
  consumed_at          TIMESTAMP COMMENT '[OPT-7] Timestamp when agent claimed the handoff',
  consuming_agent_id   STRING    COMMENT '[OPT-7] Agent instance ID that consumed this block',
  consumed_by_run_id   STRING    COMMENT 'Downstream run that consumed this handoff',
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_handoff_blocks PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-7] Pre-formatted handoff blocks from CCA to downstream steps. consumption_status prevents multi-agent race conditions.';

-- ============================================================================
-- SCHEMA: step2_gap (GAP17 Outputs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.runs (
  run_id                    STRING  NOT NULL,
  program_id                STRING,
  run_date                  DATE,
  prompt_version            STRING,
  upstream_cluster_run_id   STRING  COMMENT 'FK to step1_cluster.runs',
  c1_handoff_used           BOOLEAN,
  phase2_artifact_path      STRING  COMMENT 'Phase 2 save checkpoint — CRITICAL for C6 vocab drift check in ARV20',
  phase2_saved              BOOLEAN COMMENT 'Was Phase 2 artifact saved before Phase 3 began?',
  full_artifact_path        STRING,
  executive_summary         STRING  COMMENT 'Key findings narrative',
  created_at                TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT 'One row per GAP17 execution';

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.article_content_audit (
  id                  STRING NOT NULL,
  run_id              STRING,
  article_id          STRING,
  main_topic          STRING,
  subtopics           STRING COMMENT 'JSON array',
  primary_keywords    STRING COMMENT 'JSON array',
  semantic_variations STRING COMMENT 'JSON array',
  search_intent       STRING,
  content_type        STRING,
  assigned_cluster    STRING COMMENT 'Topic cluster name',
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_article_audit PRIMARY KEY (id)
) USING DELTA
COMMENT 'Phase 1 per-article content audit from GAP17';

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.topic_clusters (
  cluster_id                 STRING NOT NULL,
  run_id                     STRING,
  cluster_name               STRING,
  search_intent              STRING COMMENT 'Primary intent',
  article_count              INT    COMMENT 'Current coverage',
  estimated_monthly_volume   INT,
  created_at                 TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_clusters PRIMARY KEY (cluster_id)
) USING DELTA
COMMENT 'Topic clusters identified by GAP17';

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.gap_topics (
  gap_id                       STRING NOT NULL,
  run_id                       STRING,
  cluster_id                   STRING  COMMENT 'FK to topic_clusters',
  program_id                   STRING,
  gap_title                    STRING,
  priority                     STRING  COMMENT 'High, Medium',
  opportunity_score            DOUBLE  COMMENT '1-10',
  score_volume_component       DOUBLE  COMMENT '0-1',
  score_kd_component           DOUBLE  COMMENT '0-1',
  score_intent_component       DOUBLE  COMMENT '0-1',
  score_competition_component  DOUBLE  COMMENT '0-1',
  score_authority_component    DOUBLE  COMMENT '0-1',
  primary_keyword              STRING,
  keyword_volume               INT,
  keyword_kd                   DOUBLE,
  content_type_recommendation  STRING,
  estimated_traffic_potential  STRING,
  rationale                    STRING,
  has_existing_content         BOOLEAN,
  existing_article_id          STRING,
  routing_decision             STRING  COMMENT 'C3 (ideation), C4 (audit), C8 (fast-lane)',
  created_at                   TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_topics PRIMARY KEY (gap_id)
) USING DELTA
COMMENT 'Prioritized gap topics from GAP17 Phase 4';

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.gap_keywords (
  id         STRING NOT NULL,
  gap_id     STRING COMMENT 'FK to gap_topics',
  keyword    STRING,
  volume     INT,
  kd         DOUBLE,
  source     STRING COMMENT 'matching-terms, related-terms, search-suggestions, paa',
  created_at TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_keywords PRIMARY KEY (id)
) USING DELTA
COMMENT 'Related keywords per gap topic (6-10 per gap)';

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.optimization_opportunities (
  id               STRING NOT NULL,
  run_id           STRING,
  article_id       STRING,
  current_position DOUBLE,
  missing_elements STRING,
  keywords_to_target STRING,
  created_at       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_optim PRIMARY KEY (id)
) USING DELTA
COMMENT 'Existing articles flagged for optimization (feeds C4 to ARID14)';

CREATE TABLE IF NOT EXISTS risepoint_content.step2_gap.new_cluster_recommendations (
  id                    STRING NOT NULL,
  run_id                STRING,
  cluster_theme         STRING,
  rationale             STRING,
  estimated_opportunity STRING,
  created_at            TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_gap_new_clusters PRIMARY KEY (id)
) USING DELTA
COMMENT 'Strategic new topic cluster recommendations';

-- ============================================================================
-- SCHEMA: step3_audit (ARID14 Outputs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step3_audit.runs (
  run_id                           STRING  NOT NULL,
  program_id                       STRING,
  run_date                         DATE,
  prompt_version                   STRING,
  upstream_cluster_run_id          STRING,
  upstream_gap_run_id              STRING,
  c5_handoff_used                  BOOLEAN,
  ahrefs_domain_traffic_estimate   INT,
  gsc_actual_monthly_clicks        INT     COMMENT 'Domain total — ground truth',
  overestimation_ratio             DOUBLE  COMMENT 'Ahrefs estimate / GSC actual',
  artifact_path                    STRING  COMMENT 'Excel workbook path',
  created_at                       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_audit_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT 'One row per ARID14 execution';

CREATE TABLE IF NOT EXISTS risepoint_content.step3_audit.articles (
  id                           STRING  NOT NULL,
  run_id                       STRING,
  article_id                   STRING,
  -- Tab 2: Inventory
  http_status                  INT,
  publish_date                 DATE,
  last_modified_date           DATE,
  content_age_category         STRING  COMMENT 'Fresh/Current/Aging/Aging-Extended/Stale',
  outdated_references          STRING  COMMENT 'JSON array of flagged items',
  word_count                   INT,
  subheading_count             INT,
  -- Tab 4: Performance (GSC first — ground truth)
  gsc_clicks_90d               INT     COMMENT 'Actual clicks from Google Search Console — ground truth',
  gsc_monthly_clicks           DOUBLE  COMMENT '90d clicks / 3',
  gsc_impressions_90d          INT,
  gsc_ctr                      DOUBLE,
  gsc_avg_position             DOUBLE,
  gsc_ctr_expected             DOUBLE  COMMENT 'Benchmark CTR for this position',
  gsc_ctr_performance_ratio    DOUBLE  COMMENT 'actual / expected',
  is_zero_click                BOOLEAN COMMENT 'impressions > 0 AND clicks = 0',
  ahrefs_traffic_estimate      INT     COMMENT 'Ahrefs estimated traffic — can overestimate 3-15x vs GSC actual',
  estimate_vs_actual_ratio     DOUBLE,
  traffic_change_6mo           DOUBLE  COMMENT 'Percent change',
  total_ranking_keywords       INT,
  keywords_pos_1_3             INT,
  keywords_pos_4_10            INT,
  keywords_pos_11_20           INT,
  keywords_pos_21_50           INT,
  primary_keyword              STRING,
  primary_keyword_position     INT,
  referring_domains            INT,
  competitor_1_word_count      INT,
  competitor_2_word_count      INT,
  competitor_3_word_count      INT,
  competitor_median_word_count INT,
  flesch_readability           DOUBLE,
  -- Tab 5: Refresh Priority
  rps_score                    DOUBLE  COMMENT 'Refresh Priority Score 0-10. Critical >= 8, High 6-7.9, Medium 4-5.9, Low 2-3.9, Healthy 0-1.9',
  rps_decline_severity         DOUBLE  COMMENT 'Component 0-1',
  rps_opportunity_size         DOUBLE,
  rps_content_staleness        DOUBLE,
  rps_competitive_vulnerability DOUBLE,
  rps_strategic_importance     DOUBLE,
  priority_tier                STRING  COMMENT 'Critical/High/Medium/Low/Healthy',
  cluster_status               STRING  COMMENT 'Healthy/Outlier-Poor/Outlier-Moderate/Misclassified/Cross-Program/Orphan',
  refresh_triggers             STRING  COMMENT 'JSON object with 15+ boolean flags',
  routing_decision             STRING  COMMENT 'Route A = refresh existing, Route B = retire/redirect, Route C = replace with new, Monitor = watch list',
  created_at                   TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_audit_articles PRIMARY KEY (id)
) USING DELTA
COMMENT 'One row per article audited. Consolidates all 8 ARID14 workbook tabs per article.';

CREATE TABLE IF NOT EXISTS risepoint_content.step3_audit.external_links (
  id                  STRING NOT NULL,
  audit_article_id    STRING COMMENT 'FK to articles',
  article_id          STRING COMMENT 'FK to core.articles',
  external_url        STRING,
  anchor_text         STRING,
  status_code         INT,
  status_category     STRING COMMENT 'Live, Redirect, Broken, Server Error, Timeout',
  redirect_destination STRING,
  link_context        STRING,
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_audit_links PRIMARY KEY (id)
) USING DELTA
COMMENT 'Tab 3: External links audit per article';

CREATE TABLE IF NOT EXISTS risepoint_content.step3_audit.keyword_rankings (
  id               STRING NOT NULL,
  audit_article_id STRING,
  article_id       STRING,
  keyword          STRING,
  position         INT,
  volume           INT,
  kd               DOUBLE,
  position_band    STRING COMMENT '1-3, 4-10, 11-30, 31-50, 51-100',
  created_at       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_audit_keywords PRIMARY KEY (id)
) USING DELTA
COMMENT 'Tab 6: All ranking keywords per article. Join to intelligence.ahrefs_organic_keywords via keyword + target_url/article_url match for raw API source.';

CREATE TABLE IF NOT EXISTS risepoint_content.step3_audit.keyword_opportunities (
  id               STRING  NOT NULL,
  audit_article_id STRING,
  article_id       STRING,
  keyword          STRING,
  volume           INT,
  kd               DOUBLE,
  traffic_potential INT,
  search_intent    STRING,
  competitor_ranks  BOOLEAN,
  gap_type         STRING  COMMENT 'Competitive Gap / Vocabulary Drift',
  competitive_priority STRING COMMENT 'HIGH requires volume >= 500 AND KD <= 40. KD > 40 = MEDIUM regardless of volume.',
  created_at       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_audit_opportunities PRIMARY KEY (id)
) USING DELTA
COMMENT 'Tab 7: Gap keywords with KD. HIGH requires volume >= 500 AND KD <= 40.';

CREATE TABLE IF NOT EXISTS risepoint_content.step3_audit.recommendations (
  id                         STRING NOT NULL,
  audit_article_id           STRING,
  article_id                 STRING,
  must_have_updates          STRING,
  should_have_updates        STRING,
  nice_to_have_updates       STRING,
  outdated_elements          STRING,
  top_competitor_urls        STRING COMMENT 'JSON array — discrete structured list of top 3; required for ARV20 Pre-Work Package',
  competitor_advantages      STRING,
  missing_subtopics          STRING,
  subtopics_with_volume      STRING,
  broken_links               STRING COMMENT 'JSON array',
  redirect_links             STRING COMMENT 'JSON array',
  target_keywords            STRING,
  faq_question_topics        STRING,
  ctr_optimization_actions   STRING,
  traffic_recovery_potential STRING,
  new_traffic_potential      STRING,
  serp_features_lost         STRING,
  created_at                 TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_audit_recs PRIMARY KEY (id)
) USING DELTA
COMMENT 'Tab 8: Recommendations — primary handoff artifact to ARV20. top_competitor_urls must be a discrete 3-URL list for Pre-Work Assembly Agent.';

-- ============================================================================
-- SCHEMA: step4_ideation (CCW68 Phase 0D Outputs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.runs (
  run_id                           STRING  NOT NULL,
  program_id                       STRING,
  run_date                         DATE,
  prompt_version                   STRING,
  upstream_cluster_run_id          STRING,
  upstream_gap_run_id              STRING,
  c2_handoff_used                  BOOLEAN,
  c3_prequalified_topics_used      BOOLEAN,
  program_intelligence             STRING  COMMENT 'JSON — extracted program page data',
  created_at                       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT 'One row per Phase 0D Topic Prioritization execution';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.foundation_keywords (
  id                STRING NOT NULL,
  run_id            STRING,
  keyword           STRING,
  volume            INT,
  kd                DOUBLE,
  traffic_potential INT,
  serp_features     STRING COMMENT 'JSON array',
  created_at        TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_foundation PRIMARY KEY (id)
) USING DELTA
COMMENT 'Foundation keywords from Ahrefs for the program';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.matching_terms (
  id                STRING NOT NULL,
  run_id            STRING,
  keyword           STRING,
  volume            INT,
  kd                DOUBLE,
  traffic_potential INT,
  notes             STRING,
  created_at        TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_matching PRIMARY KEY (id)
) USING DELTA
COMMENT 'High opportunity matching terms (KD <= 40, Vol >= 200)';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.topic_analysis (
  id                  STRING NOT NULL,
  run_id              STRING,
  topic_theme         STRING,
  category            STRING COMMENT 'HIGH-IMPACT / EMERGING',
  volume              INT,
  kd                  DOUBLE,
  program_connection  STRING COMMENT 'Narrative',
  cta_potential       INT    COMMENT '1-10 score',
  growth_indicator    STRING COMMENT 'For EMERGING topics',
  quick_win_potential STRING COMMENT 'HIGH/MEDIUM/LOW',
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_topics PRIMARY KEY (id)
) USING DELTA
COMMENT 'Topic analysis with CTA Potential scoring';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.content_series (
  id                       STRING NOT NULL,
  run_id                   STRING,
  series_name              STRING,
  combined_monthly_volume  INT,
  linking_hub_keyword      STRING,
  linking_hub_volume       INT,
  created_at               TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_series PRIMARY KEY (id)
) USING DELTA
COMMENT 'Content series groupings (3+ related articles)';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.content_series_articles (
  id                 STRING NOT NULL,
  series_id          STRING COMMENT 'FK to content_series',
  article_title      STRING COMMENT 'Proposed title',
  primary_keyword    STRING,
  volume             INT,
  kd                 DOUBLE,
  position_in_series INT,
  created_at         TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_series_articles PRIMARY KEY (id)
) USING DELTA
COMMENT 'Individual articles within a content series';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.competitive_gaps (
  id                    STRING NOT NULL,
  run_id                STRING,
  gap_keyword           STRING,
  volume                INT,
  kd                    DOUBLE,
  why_underserved       STRING,
  positioning_strategy  STRING,
  created_at            TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_gaps PRIMARY KEY (id)
) USING DELTA
COMMENT 'Competitive gaps with positioning strategy';

CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.priority_topics (
  id                           STRING NOT NULL,
  run_id                       STRING,
  rank                         INT    COMMENT '1-5',
  topic_title                  STRING,
  primary_keyword              STRING,
  volume                       INT,
  kd                           DOUBLE,
  traffic_potential            INT,
  cta_potential                INT    COMMENT '1-10',
  program_connection           STRING,
  content_to_conversion_path   STRING,
  aeo_angle                    STRING COMMENT 'AI Overview, PAA, featured snippet strategy',
  expected_outcome             STRING COMMENT 'Traffic estimate at ranking',
  created_at                   TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_priority PRIMARY KEY (id)
) USING DELTA
COMMENT 'Top 5 Priority Topics output from Phase 0D';

-- [OPT-7] handoff_blocks: consumption_status replaces simple boolean.
CREATE TABLE IF NOT EXISTS risepoint_content.step4_ideation.handoff_blocks (
  id                              STRING  NOT NULL,
  priority_topic_id               STRING  COMMENT 'FK to priority_topics',
  run_id                          STRING,
  program_context                 STRING,
  program_url                     STRING,
  key_differentiators             STRING,
  selected_topic                  STRING,
  primary_keyword                 STRING,
  keyword_volume                  INT,
  keyword_kd                      DOUBLE,
  keyword_tp                      INT,
  related_keywords                STRING  COMMENT 'JSON array',
  content_type                    STRING,
  strategic_rationale             STRING,
  content_to_conversion_strategy  STRING,
  expected_outcome                STRING,
  consumption_status              STRING  DEFAULT 'pending' COMMENT '[OPT-7] pending / in_progress / consumed / failed',
  consumed_at                     TIMESTAMP COMMENT '[OPT-7] When agent claimed this handoff',
  consuming_agent_id              STRING    COMMENT '[OPT-7] Agent instance ID',
  consumed_by_run_id              STRING,
  created_at                      TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ideation_handoffs PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-7] Per-topic handoff blocks to Step 5b. consumption_status prevents race conditions.';

-- ============================================================================
-- SCHEMA: step5_refresh (ARV20 Outputs)
--
-- [OPT-1] DESIGN CHANGE FROM v2.0:
-- The v2.0 single-table design crammed 90+ columns into step5_refresh.runs.
-- Any gate behavior change (e.g., ARV20 v2.1 Gate 1 restructuring) required
-- column-level DDL changes. This is brittle for a workflow under active development.
--
-- v2.1 splits into:
--   runs          — header row (identity, timing, overall status)
--   gate0_metrics — Pre-Work Package assembly data (keyword baseline, WC benchmark)
--   gate1_metrics — Refresh Strategy (POV, threshold declaration, phrase log status)
--   gate2_metrics — Source gathering (exclusion counts, feedback loop flag)
--   gate3_metrics — Content updates (compliance checks, change %, deferred gaps)
--   gate4_metrics — Quality audit (artifact paths, word count, highlight counts)
--   gate45_metrics — SWA optimization (nullable — only populated when triggered)
--
-- Adding a new gate field = INSERT column into the relevant gate table only.
-- Querying a single gate = join runs + one gate table, not a 90-column scan.
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.runs (
  run_id              STRING NOT NULL,
  article_id          STRING COMMENT 'FK to core.articles',
  program_id          STRING COMMENT 'FK to core.programs',
  run_date            DATE,
  prompt_version      STRING COMMENT 'e.g., 2.1 — must match config registry to avoid KI-02 class issues',
  mode                STRING COMMENT 'orchestrated / standalone',
  upstream_audit_run_id STRING COMMENT 'FK to step3_audit.runs',
  status              STRING COMMENT 'in_progress / complete / blocked',
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  updated_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT '[OPT-1] Header row per ARV20 execution. Gate detail in gate0-gate45 tables. Join on run_id.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate0_metrics (
  id                             STRING NOT NULL,
  run_id                         STRING NOT NULL COMMENT 'FK to runs',
  total_ranking_keywords         INT,
  optimization_targets           INT    COMMENT 'Keywords in positions 11-30',
  consolidation_risks            INT    COMMENT 'Keywords in positions 50+',
  gap_keywords_total             INT,
  gap_keywords_high              INT    COMMENT 'Competitive priority HIGH (vol >= 500, KD <= 40)',
  drift_terms_actionable         INT,
  competitor_wc_1                INT,
  competitor_wc_2                INT,
  competitor_wc_3                INT,
  competitor_wc_median           INT,
  competitor_wc_range_low        INT    COMMENT 'Median - 15%',
  competitor_wc_range_high       INT    COMMENT 'Median + 15%',
  current_wc                     INT,
  wc_delta                       INT    COMMENT 'current - median; negative = article is shorter',
  competitor_flesch_1            DOUBLE,
  competitor_flesch_2            DOUBLE,
  competitor_flesch_3            DOUBLE,
  competitor_flesch_median       DOUBLE,
  current_flesch                 DOUBLE,
  flesch_delta                   DOUBLE,
  created_at                     TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate0 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 0 Pre-Work Package metrics per ARV20 run. Replaces 20+ columns in v2.0 runs table.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate1_metrics (
  id                          STRING  NOT NULL,
  run_id                      STRING  NOT NULL COMMENT 'FK to runs',
  pov_you_count               INT,
  pov_they_count              INT,
  pov_dominant                STRING  COMMENT 'second-person / third-person',
  pov_conversions_needed      INT,
  program_link_present        BOOLEAN,
  program_link_correct        STRING  COMMENT 'CONFIRMED / FLAGGED / STOPPED',
  citation_inheritance_count  INT,
  prior_phrase_log_status     STRING  COMMENT 'PROVIDED / NOT PROVIDED — NOT PROVIDED = first refresh cycle',
  estimated_change_pct        DOUBLE,
  five_source_minimum         BOOLEAN COMMENT 'true when estimated_change_pct > 30',
  gate1_status                STRING  COMMENT 'PASS / FAIL / STOPPED',
  validation_details          STRING  COMMENT 'JSON — 12-item checklist results',
  created_at                  TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate1 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 1 Refresh Strategy metrics per ARV20 run. Replaces 12+ columns in v2.0 runs table.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate2_metrics (
  id                         STRING  NOT NULL,
  run_id                     STRING  NOT NULL COMMENT 'FK to runs',
  sources_evaluated          INT,
  sources_passed             INT,
  sources_excluded           INT,
  exclusion_reasons          STRING  COMMENT 'JSON array of failure reasons',
  feedback_loop_triggered    BOOLEAN COMMENT 'true = returned to Gate 1 (designed recovery, not a failure)',
  url_uniqueness_status      STRING  COMMENT 'PASS / FAIL',
  gate2_status               STRING  COMMENT 'PASS / FAIL',
  created_at                 TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate2 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 2 Source Gathering metrics per ARV20 run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate25_metrics (
  id                           STRING  NOT NULL,
  run_id                       STRING  NOT NULL COMMENT 'FK to runs',
  all_sources_within_recency   BOOLEAN,
  accessibility_issues         INT     COMMENT 'Stats not on linked page',
  editorial_flags              INT,
  terminology_matches          BOOLEAN,
  gate25_status                STRING  COMMENT 'PASS / PASS WITH FLAGS / FAIL',
  created_at                   TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate25 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 2.5 Data and Source Verification metrics per ARV20 run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate3_metrics (
  id                        STRING  NOT NULL,
  run_id                    STRING  NOT NULL COMMENT 'FK to runs',
  citation_compliance       STRING  COMMENT 'PASS / FAIL',
  content_integration       STRING  COMMENT 'PASS / FAIL',
  source_quality            STRING  COMMENT 'PASS / FAIL',
  keyword_integration       STRING  COMMENT 'PASS / FAIL',
  program_variation         STRING  COMMENT 'PASS / FAIL / N/A',
  readability_delta         STRING  COMMENT 'ACKNOWLEDGED / N/A',
  change_constraint         STRING  COMMENT 'PASS / FAIL',
  actual_change_pct         DOUBLE,
  deferred_gaps             STRING  COMMENT 'JSON array — POV conflict keywords deferred per Gate 1 conflict note',
  gate3_status              STRING  COMMENT 'PASS / FAIL',
  validation_details        STRING  COMMENT 'JSON — full checklist results',
  created_at                TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate3 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 3 Content Updates metrics per ARV20 run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate35_metrics (
  id                          STRING NOT NULL,
  run_id                      STRING NOT NULL COMMENT 'FK to runs',
  oxford_commas_removed       INT,
  passive_voice_found         INT,
  passive_voice_corrected     INT,
  paragraph_violations        INT,
  readability_priority        STRING COMMENT 'elevated / standard',
  gate35_status               STRING COMMENT 'PASS / FAIL',
  created_at                  TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate35 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 3.5 Style Edit metrics per ARV20 run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate4_metrics (
  id                     STRING NOT NULL,
  run_id                 STRING NOT NULL COMMENT 'FK to runs',
  artifact_path_md       STRING COMMENT 'Markdown article path',
  artifact_path_docx     STRING COMMENT 'Color-coded tracked-changes .docx path',
  phrase_log_path        STRING COMMENT 'Updated Program Detail Phrase Log path',
  final_word_count       INT,
  final_flesch           DOUBLE,
  sources_added          INT,
  sources_removed        INT,
  highlight_yellow       INT    COMMENT 'Count of modified sections',
  highlight_green        INT    COMMENT 'Count of new sections',
  highlight_blue         INT    COMMENT 'Count of stat updates',
  gate4_status           STRING COMMENT 'COMPLETE',
  created_at             TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate4 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 4 Quality Audit metrics and artifact locations per ARV20 run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.gate45_metrics (
  id                       STRING NOT NULL,
  run_id                   STRING NOT NULL COMMENT 'FK to runs — nullable gate; only exists when SWA triggered',
  swa_score_input          DOUBLE,
  primary_gap_source       STRING COMMENT 'Readability / SEO / Tone / Mixed',
  keywords_added           STRING COMMENT 'JSON array',
  vocab_substitutions      INT,
  sentences_rewritten      INT,
  paragraphs_split         INT,
  active_voice_converted   INT,
  filler_removed           INT,
  wc_before                INT,
  wc_after                 INT,
  swa_score_output         DOUBLE,
  score_routing            STRING COMMENT 'acceptable / surface_to_editor',
  editorial_escalations    INT,
  created_at               TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_gate45 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-1] Gate 4.5 SWA Optimization metrics. Nullable — only populated when score triggers SWA run (6.5-7.9 band).';

-- Detail tables unchanged from v2.0 (strategy_rows, source_exclusions, etc.)

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.strategy_rows (
  id                    STRING NOT NULL,
  run_id                STRING,
  section_name          STRING COMMENT 'e.g., Introduction para 1, H2 Sec 2 para 3, [NEW SECTION]',
  change_type           STRING COMMENT 'Modernize, Add statistic, Remove/replace, Add new H2, Restructure',
  source_needed         BOOLEAN,
  quote_audit           STRING,
  structure_assessment  STRING,
  quality_opportunity   STRING,
  keyword_opportunity   STRING COMMENT 'Gap keyword or drift term from Pre-Work Package',
  competitive_priority  STRING COMMENT 'HIGH / MEDIUM / LOW',
  notes                 STRING,
  created_at            TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_strategy PRIMARY KEY (id)
) USING DELTA
COMMENT 'Gate 1 Refresh Strategy Table — per-section change plan';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.source_exclusions (
  id                  STRING  NOT NULL,
  run_id              STRING,
  source_url          STRING,
  source_org          STRING,
  check_no_edu        BOOLEAN,
  check_loads         BOOLEAN,
  check_no_uni_content BOOLEAN,
  check_no_uni_nav    BOOLEAN,
  check_no_uni_sidebar BOOLEAN,
  check_no_uni_footer  BOOLEAN,
  check_pub_date_ok   BOOLEAN,
  check_no_paywall    BOOLEAN,
  check_no_rankings   BOOLEAN,
  check_data_extracted BOOLEAN,
  passed              BOOLEAN COMMENT 'All 10 checks passed',
  failure_reason      STRING,
  source_category     STRING  COMMENT 'Govt, Professional, Academic, Industry',
  source_tier         STRING  COMMENT 'Tier 1, 2, 3',
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_exclusions PRIMARY KEY (id)
) USING DELTA
COMMENT 'Gate 2 Source Exclusion Protocol — 10 checks per source';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.citation_prep (
  id                     STRING  NOT NULL,
  run_id                 STRING,
  claim                  STRING  COMMENT 'Factual claim text',
  source_org             STRING,
  source_category        STRING,
  publication_year       INT,
  data_quote             STRING  COMMENT 'Exact verbatim quote from source',
  url                    STRING,
  tool_used              STRING  COMMENT 'playwright, web_fetch',
  template               STRING  COMMENT 'A / B',
  already_introduced     BOOLEAN COMMENT 'From Citation Inheritance Map',
  attribution_phrasing   STRING  COMMENT 'Planned unique phrasing',
  used                   BOOLEAN COMMENT 'Applied in article',
  created_at             TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_citations PRIMARY KEY (id)
) USING DELTA
COMMENT 'Gate 2 Citation Preparation Table';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.keyword_integration (
  id               STRING  NOT NULL,
  run_id           STRING,
  keyword          STRING,
  source           STRING  COMMENT 'Phase B gap, Phase C drift, Gate 0 recommendation',
  targeted_section STRING,
  appears_in_content BOOLEAN,
  natural_fit      BOOLEAN,
  deferred         BOOLEAN COMMENT 'Deferred due to POV conflict documented in Gate 1',
  deferral_reason  STRING,
  created_at       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_keywords PRIMARY KEY (id)
) USING DELTA
COMMENT 'Gate 3 keyword integration tracking per keyword';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_refresh.phrase_log_entries (
  id               STRING NOT NULL,
  run_id           STRING,
  program_id       STRING,
  article_id       STRING,
  program_fact     STRING COMMENT 'e.g., Program format reference, Credit hours',
  exact_phrasing   STRING COMMENT 'Exact sentence fragment used in article',
  variation_status STRING COMMENT 'First refresh / Verified different from X prior',
  created_at       TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_refresh_phrases PRIMARY KEY (id)
) USING DELTA
COMMENT 'Program Detail Phrase Log entries for cross-article variation tracking';

-- ============================================================================
-- SCHEMA: step5_creation (CCW68 Outputs)
--
-- [OPT-2] DESIGN CHANGE FROM v2.0:
-- Same rationale as step5_refresh. The v2.0 single table had 60+ columns.
-- Gate 4 audit columns alone spanned ~25 fields. v2.1 splits into:
--   runs          — header (keyword, entry point, route, status)
--   module1_data  — SEO Specification Package (competitor benchmarks, keywords)
--   module2_data  — Content Brief (content type, AEO headings, citation template)
--   gate4_results — 9-Audit system results (all 9 audits + SEO Quality Score)
--   swa_data      — SWA optimization (nullable — only when triggered)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.runs (
  run_id                      STRING NOT NULL,
  program_id                  STRING,
  run_date                    DATE,
  prompt_version              STRING COMMENT 'e.g., 6.8',
  entry_point                 STRING COMMENT 'A, B, C, D, E',
  route                       STRING COMMENT 'C, D, E',
  primary_keyword             STRING,
  secondary_target_keyword    STRING,
  upstream_gap_run_id         STRING,
  upstream_cluster_run_id     STRING,
  upstream_ideation_run_id    STRING,
  status                      STRING COMMENT 'in_progress / complete / blocked',
  created_at                  TIMESTAMP DEFAULT current_timestamp(),
  updated_at                  TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT '[OPT-2] Header row per CCW68 execution. Module and gate detail in child tables. Join on run_id.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.module1_data (
  id                      STRING NOT NULL,
  run_id                  STRING NOT NULL COMMENT 'FK to runs',
  seo_spec_data           STRING COMMENT 'JSON — full SEO Specification Package',
  competitor_wc_median    INT,
  competitor_wc_range_low INT    COMMENT 'Median - 15%',
  competitor_wc_range_high INT   COMMENT 'Median + 15%',
  competitor_flesch_avg   DOUBLE,
  flesch_target           DOUBLE,
  recommended_keywords_count INT,
  created_at              TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_module1 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-2] CCW68 Module 1 SEO Specification output per run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.module2_data (
  id                STRING  NOT NULL,
  run_id            STRING  NOT NULL COMMENT 'FK to runs',
  content_type      STRING  COMMENT 'TYPE 1/2/3',
  citation_template STRING  COMMENT 'A / B',
  aeo_h2_count      INT     COMMENT 'Number of question-format H2s planned',
  sources_evaluated INT,
  sources_passed    INT,
  sources_excluded  INT,
  gate1_source_diversity STRING COMMENT 'PASS / FAIL — Gate 1 Source Diversity Pre-Check',
  created_at        TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_module2 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-2] CCW68 Module 2 Content Brief + Gate 1 source diversity output per run.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.gate4_results (
  id                          STRING  NOT NULL,
  run_id                      STRING  NOT NULL COMMENT 'FK to runs',
  audit1_source_diversity     STRING  COMMENT 'PASS / FAIL',
  audit2_citation_accuracy    STRING  COMMENT 'PASS / FAIL',
  audit3_source_recency       STRING  COMMENT 'PASS / FAIL',
  audit4_url_uniqueness       STRING  COMMENT 'PASS / FAIL',
  audit5_paragraph_minimums   STRING  COMMENT 'PASS / FAIL',
  audit6_h3_compliance        STRING  COMMENT 'PASS / FAIL',
  audit7_program_links        STRING  COMMENT 'PASS / FAIL',
  audit8_header_hierarchy     STRING  COMMENT 'PASS / FAIL',
  audit9_seo_quality_score    DOUBLE  COMMENT 'SEO Quality Score 0-10. Pass >= 8.0, Surface to editor 6.5-7.9, Auto-iterate < 6.5',
  audit9_keyword_coverage_pct DOUBLE,
  audit9_flesch_score         DOUBLE,
  audit9_details              STRING  COMMENT 'JSON — full Audit 9 breakdown',
  artifact_path               STRING,
  final_word_count            INT,
  final_flesch                DOUBLE,
  program_links_count         INT     COMMENT 'Should be 3',
  aeo_faq_schema              BOOLEAN,
  ai_overview_optimized       BOOLEAN,
  created_at                  TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_gate4 PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-2] CCW68 Gate 4 9-Audit system results per run. SEO Quality Score >= 8.0 required to advance.';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.swa_data (
  id                      STRING  NOT NULL,
  run_id                  STRING  NOT NULL COMMENT 'FK to runs — nullable; only exists when SWA triggered',
  swa_score_pre           DOUBLE,
  swa_score_post          DOUBLE,
  swa_gap_source          STRING  COMMENT 'Readability / SEO / Tone / Mixed',
  keywords_added          STRING  COMMENT 'JSON array',
  vocab_substitutions     INT,
  sentences_rewritten     INT,
  created_at              TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_swa PRIMARY KEY (id)
) USING DELTA
COMMENT '[OPT-2] CCW68 SWA optimization data. Nullable — only populated when score triggers SWA (6.5-7.9 band).';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.recommended_keywords (
  id                   STRING  NOT NULL,
  run_id               STRING,
  keyword              STRING,
  exact_phrase_form    STRING  COMMENT 'The exact form to use in article body',
  volume               INT,
  priority             STRING  COMMENT 'HIGH / MEDIUM',
  source_count         INT     COMMENT 'How many of 5 sources this keyword appeared in',
  sources              STRING  COMMENT 'JSON array — which sources',
  integrated_in_article BOOLEAN,
  integrated_section   STRING  COMMENT 'Which H2 section',
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_keywords PRIMARY KEY (id)
) USING DELTA
COMMENT 'Module 1 recommended keywords with exact phrase forms and integration tracking';

CREATE TABLE IF NOT EXISTS risepoint_content.step5_creation.competitor_analysis (
  id                STRING NOT NULL,
  run_id            STRING,
  competitor_url    STRING,
  competitor_domain STRING,
  serp_position     INT    COMMENT 'Position for primary keyword',
  page_traffic      INT,
  page_keywords     INT,
  word_count        INT    COMMENT 'Body word count',
  flesch_score      DOUBLE COMMENT 'FRE calculator result',
  h2_structure      STRING COMMENT 'JSON array of H2 headings',
  strengths         STRING,
  weaknesses        STRING,
  created_at        TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_creation_competitors PRIMARY KEY (id)
) USING DELTA
COMMENT 'Module 1 competitor content analysis (top 3 SERP competitors)';

-- ============================================================================
-- SCHEMA: step6_swa (M6SWA1 Outputs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.step6_swa.runs (
  run_id               STRING  NOT NULL,
  source_type          STRING  COMMENT 'refresh / creation',
  source_run_id        STRING  COMMENT 'FK to step5_refresh.runs or step5_creation.runs',
  run_date             DATE,
  prompt_version       STRING,
  seo_spec_available   BOOLEAN COMMENT 'FALSE for refresh path — no SEO spec in ARV20',
  -- Input signals
  swa_score_input      DOUBLE,
  swa_readability_input DOUBLE COMMENT 'Flesch from SWA tool',
  swa_readability_target DOUBLE,
  readability_flags    STRING  COMMENT 'JSON array',
  seo_flags            STRING  COMMENT 'JSON array',
  tone_flags           STRING  COMMENT 'JSON array',
  originality_score    DOUBLE,
  smart_writer_words   STRING  COMMENT 'X / X format',
  -- Diagnostics
  fre_asl              DOUBLE  COMMENT 'Average sentence length (words per sentence)',
  fre_asw              DOUBLE  COMMENT 'Average syllables per word',
  fre_calculated       DOUBLE  COMMENT 'Our FRE calculator result',
  flesch_gap           DOUBLE  COMMENT 'Points below target',
  primary_gap_source   STRING  COMMENT 'Readability / SEO / Tone / Mixed',
  -- Fixes applied
  keywords_added       STRING  COMMENT 'JSON array',
  vocab_substitutions  INT,
  sentences_rewritten  INT,
  paragraphs_split     INT,
  active_voice_converted INT,
  active_voice_preserved INT,
  filler_removed       INT,
  wc_before            INT,
  wc_after             INT,
  wc_conflict_resolution STRING COMMENT 'Maintained / Reduced / Escalated',
  editorial_escalations INT,
  monitor_tier_flags   STRING  COMMENT 'JSON array',
  -- Output
  swa_score_output     DOUBLE,
  score_routing        STRING  COMMENT 'acceptable / surface_to_editor',
  artifact_path        STRING,
  round_number         INT     COMMENT 'SWA optimization round (1, 2, ...)',
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_swa_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT 'One row per M6SWA1 execution with diagnostics and fix tracking';

-- ============================================================================
-- SCHEMA: orchestration (State, Artifacts, Routing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.orchestration.workflow_state (
  id                   STRING NOT NULL,
  client_id            STRING,
  program_id           STRING,
  current_phase        STRING COMMENT 'Phase 1: Assess / Phase 2: Decide & Ideate / Phase 3: Execute',
  current_step         STRING COMMENT 'Step 1-6',
  blocking_dependency  STRING,
  last_completed_step  STRING,
  last_completed_date  DATE,
  next_action          STRING COMMENT 'Human-readable next action',
  status               STRING COMMENT 'active / paused / complete',
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  updated_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_workflow_state PRIMARY KEY (id)
) USING DELTA
COMMENT 'Master state tracker — one row per client/program workflow instance';

-- [OPT-4] artifacts: added multi-environment location fields.
-- Agents resolving artifacts need Confluence page ID and SharePoint/OneDrive
-- paths — a file_path string alone does not resolve in automated environments.
-- Confluence MCP returns page IDs; Microsoft Graph returns item IDs.
-- At least one of file_path / confluence_page_id / sharepoint_item_id must be populated.
CREATE TABLE IF NOT EXISTS risepoint_content.orchestration.artifacts (
  artifact_id          STRING NOT NULL,
  client_id            STRING,
  program_id           STRING,
  artifact_type        STRING COMMENT 'cluster_analysis, gap_phase2, gap_full, article_audit, article_refresh_md, article_refresh_docx, new_article, swa_optimized, phrase_log, seo_spec, content_brief',
  step_produced        STRING,
  file_name            STRING COMMENT 'Following workflow naming convention',
  file_path            STRING COMMENT 'Local or container path (Claude Code environment)',
  confluence_page_id   STRING COMMENT '[OPT-4] Confluence page ID (from Atlassian MCP create_page response). Use for Atlassian MCP get_page retrieval.',
  confluence_page_url  STRING COMMENT '[OPT-4] Full Confluence page URL for human reference',
  sharepoint_item_id   STRING COMMENT '[OPT-4] Microsoft Graph drive item ID (from Graph API upload response). Use for Graph API file retrieval.',
  onedrive_path        STRING COMMENT '[OPT-4] OneDrive relative path (e.g., /SEO/AI Projects/.../filename). Use for Graph path-based retrieval.',
  produced_date        DATE,
  consumed_by_steps    STRING COMMENT 'JSON array of step IDs that have consumed this artifact',
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_artifacts PRIMARY KEY (artifact_id)
) USING DELTA
COMMENT '[OPT-4] Registry of every saved artifact. Multi-environment: file_path for local, confluence_page_id for Atlassian MCP, sharepoint_item_id/onedrive_path for Microsoft Graph. At least one location field must be populated.';

CREATE TABLE IF NOT EXISTS risepoint_content.orchestration.routing_decisions (
  id              STRING NOT NULL,
  program_id      STRING,
  decision_point  STRING COMMENT 'DP1-DP5',
  article_id      STRING,
  gap_id          STRING,
  route_chosen    STRING COMMENT 'A/B/C/D/E/close/monitor',
  reason          STRING,
  rps_score       DOUBLE COMMENT 'If applicable',
  decided_by      STRING COMMENT 'operator / automated',
  decided_date    DATE,
  created_at      TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_routing PRIMARY KEY (id)
) USING DELTA
COMMENT 'Log of every routing decision at Decision Points 1-5';

CREATE TABLE IF NOT EXISTS risepoint_content.orchestration.connection_log (
  id                   STRING NOT NULL,
  connection_id        STRING COMMENT 'C1-C10',
  source_step          STRING,
  source_run_id        STRING,
  target_step          STRING,
  target_run_id        STRING,
  handoff_content      STRING,
  translation_applied  BOOLEAN,
  executed_date        DATE,
  created_at           TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_connections PRIMARY KEY (id)
) USING DELTA
COMMENT 'Tracks every connection execution (C1-C10) between workflow steps';

-- [OPT-6] known_issues: first-class table for KI-01, KI-02, and future gaps.
-- These were previously tracked only in memory/project files with no
-- queryable location. Automated agents can now check this table before
-- executing affected steps and halt when a blocking issue exists.
CREATE TABLE IF NOT EXISTS risepoint_content.orchestration.known_issues (
  issue_id          STRING  NOT NULL COMMENT 'Primary key. e.g., KI-01, KI-02',
  title             STRING  NOT NULL COMMENT 'Short description',
  affected_steps    STRING  COMMENT 'JSON array of affected step IDs / connection IDs',
  severity          STRING  COMMENT 'CRITICAL / HIGH / MEDIUM / LOW',
  is_blocking       BOOLEAN COMMENT 'true = agents must halt before executing affected steps',
  description       STRING  COMMENT 'Full description of the issue',
  resolution_notes  STRING  COMMENT 'What has been done / what is needed',
  status            STRING  DEFAULT 'open' COMMENT 'open / in_progress / resolved',
  opened_date       DATE,
  resolved_date     DATE    COMMENT 'NULL if not resolved',
  created_at        TIMESTAMP DEFAULT current_timestamp(),
  updated_at        TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_known_issues PRIMARY KEY (issue_id)
) USING DELTA
COMMENT '[OPT-6] Known issues registry. Replaces memory-only tracking of KI-01 (CCA1 field verification) and KI-02 (ARV20 version mismatch). Agents check is_blocking before executing affected steps.';

-- Seed known issues from current state
INSERT INTO risepoint_content.orchestration.known_issues VALUES (
  'KI-01',
  'CCA1 v3.2 output field names unverified against C1/C2/C5 translation maps',
  '["C1","C2","C5","step1_cluster","step2_gap","step4_ideation"]',
  'HIGH',
  true,
  'The CCA1 v3.2 prompt file was never shared as a standalone file during config development. Output field names in C1, C2, C5 translation maps were inferred from session descriptions, not verified against the actual prompt. Mismatched field names will silently produce empty handoff blocks.',
  'Provide the CCA1 v3.2 prompt file for a one-time verification pass against the C1/C2/C5 translation maps. Until resolved, all CCA1 handoffs should be human-verified.',
  'open',
  current_date(),
  NULL,
  current_timestamp(),
  current_timestamp()
);

INSERT INTO risepoint_content.orchestration.known_issues VALUES (
  'KI-02',
  'WorkflowConfig v1.8 Prompt Registry lists ARV20 at v2.0 but live file is v2.1',
  '["C6","C9","step5_refresh"]',
  'MEDIUM',
  false,
  'WorkflowConfig v1.8 Prompt Registry and Version Compatibility Matrix reference ARV20 at version 2.0. The live prompt file is STEP5a_Article_Refresh_Workflow_v2_1.md. v2.1 changed Gate 1 behavior (removed M365/SharePoint dependency, replaced with operator-provided prior phrase log review). Automation built against v2.0 config will use incorrect gate structure for Gate 1.',
  'Update WorkflowConfig Prompt Registry to v2.1. Verify C6 and C9 translation maps against v2.1 gate structure before building automation against refresh path. Treat as BLOCKING for any automated pipeline.',
  'open',
  current_date(),
  NULL,
  current_timestamp(),
  current_timestamp()
);

-- ============================================================================
-- SCHEMA: ai_visibility (Brand Radar Data)
-- ============================================================================

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.analysis_runs (
  run_id             STRING NOT NULL,
  client_id          STRING,
  program_id         STRING COMMENT 'Nullable — market mode may not be program-specific',
  run_date           DATE,
  analysis_mode      STRING COMMENT 'market_visibility / content_effectiveness',
  brand_name         STRING COMMENT 'As it appears in AI responses',
  market_definition  STRING COMMENT 'Niche market string',
  competitor_brands  STRING COMMENT 'JSON array',
  data_sources_swept STRING COMMENT 'JSON array — which of 6 AI platforms',
  created_at         TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_runs PRIMARY KEY (run_id)
) USING DELTA
COMMENT 'One row per AI Visibility analysis run';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.mention_snapshots (
  id                         STRING NOT NULL,
  run_id                     STRING,
  platform                   STRING COMMENT 'google_ai_overviews, chatgpt, gemini, perplexity, copilot, google_ai_mode',
  brand                      STRING,
  total_mentions             INT,
  solo_mentions              INT,
  co_mentions                INT,
  competitor_only_mentions   INT,
  pull_date                  DATE,
  created_at                 TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_mentions PRIMARY KEY (id)
) USING DELTA
COMMENT 'Per-platform mention counts from Brand Radar';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.impression_snapshots (
  id                           STRING NOT NULL,
  run_id                       STRING,
  platform                     STRING,
  brand                        STRING,
  total_impressions            INT,
  solo_impressions             INT,
  co_impressions               INT,
  competitor_only_impressions  INT,
  unbranded_impressions        INT    COMMENT 'No tracked brand mentioned',
  pull_date                    DATE,
  created_at                   TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_impressions PRIMARY KEY (id)
) USING DELTA
COMMENT 'Per-platform impression volumes from Brand Radar';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.sov_snapshots (
  id                  STRING NOT NULL,
  run_id              STRING,
  platform            STRING,
  brand               STRING,
  share_of_voice_pct  DOUBLE,
  pull_date           DATE,
  created_at          TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_sov PRIMARY KEY (id)
) USING DELTA
COMMENT 'Share of Voice percentages per brand per platform';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.cited_domains (
  id              STRING  NOT NULL,
  run_id          STRING,
  platform        STRING,
  domain          STRING,
  response_count  INT,
  page_count      INT,
  search_volume   INT,
  is_own_domain   BOOLEAN,
  is_competitor   BOOLEAN,
  pull_date       DATE,
  created_at      TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_cited_domains PRIMARY KEY (id)
) USING DELTA
COMMENT 'Which domains are cited as sources in AI responses';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.cited_pages (
  id              STRING  NOT NULL,
  run_id          STRING,
  platform        STRING,
  page_url        STRING,
  domain          STRING,
  response_count  INT,
  search_volume   INT,
  is_own_page     BOOLEAN,
  article_id      STRING  COMMENT 'FK to core.articles if own page',
  pull_date       DATE,
  created_at      TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_cited_pages PRIMARY KEY (id)
) USING DELTA
COMMENT 'URL-level citation data from Brand Radar';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.opportunities (
  id                    STRING NOT NULL,
  run_id                STRING,
  platform              STRING,
  question              STRING COMMENT 'The AI query text',
  competitor_mentioned  STRING,
  competitor_cited_url  STRING,
  search_volume         INT,
  priority              STRING COMMENT 'HIGH / MEDIUM / LOW',
  created_at            TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_opportunities PRIMARY KEY (id)
) USING DELTA
COMMENT 'Queries where competitors appear in AI responses but client does not';

CREATE TABLE IF NOT EXISTS risepoint_content.ai_visibility.trend_data (
  id            STRING NOT NULL,
  run_id        STRING,
  platform      STRING,
  brand         STRING,
  metric_type   STRING COMMENT 'mentions / impressions / sov',
  metric_value  DOUBLE,
  period_date   DATE,
  created_at    TIMESTAMP DEFAULT current_timestamp(),
  CONSTRAINT pk_ai_trends PRIMARY KEY (id)
) USING DELTA
COMMENT 'Historical time series for mentions, impressions, and SoV';

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Articles with Route A routing and no completed refresh
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_articles_needing_refresh AS
SELECT
    a.article_url, a.article_title, p.program_name, p.client_id,
    sa.rps_score, sa.priority_tier, sa.cluster_status, sa.routing_decision,
    sa.gsc_monthly_clicks, sa.traffic_change_6mo,
    sa.primary_keyword, sa.primary_keyword_position,
    sa.competitor_median_word_count, a.word_count,
    sa.rps_decline_severity, sa.rps_opportunity_size,
    r.must_have_updates, r.should_have_updates, r.top_competitor_urls
FROM risepoint_content.step3_audit.articles sa
JOIN risepoint_content.core.articles a         ON sa.article_id = a.article_id
JOIN risepoint_content.core.programs p         ON a.program_id = p.program_id
LEFT JOIN risepoint_content.step3_audit.recommendations r ON sa.id = r.audit_article_id
WHERE sa.routing_decision = 'Route A'
  AND sa.article_id NOT IN (
    SELECT article_id FROM risepoint_content.step5_refresh.runs
    WHERE status = 'complete'
  )
ORDER BY sa.rps_score DESC;

-- High priority gap topics ready for production
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_high_priority_gaps AS
SELECT
    gt.gap_title, gt.primary_keyword, gt.keyword_volume, gt.keyword_kd,
    gt.opportunity_score, gt.score_volume_component, gt.score_kd_component,
    gt.content_type_recommendation, gt.estimated_traffic_potential,
    gt.routing_decision, p.program_name, p.client_id
FROM risepoint_content.step2_gap.gap_topics gt
JOIN risepoint_content.core.programs p ON gt.program_id = p.program_id
WHERE gt.priority = 'High' AND gt.opportunity_score >= 8
ORDER BY gt.opportunity_score DESC;

-- [OPT-1] Pre-Work Package view updated to join gate0_metrics instead of runs
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_prework_package AS
SELECT
    a.article_url, a.article_title, p.program_name,
    sa.primary_keyword, sa.primary_keyword_position,
    sa.gsc_monthly_clicks, sa.gsc_impressions_90d, sa.gsc_ctr, sa.gsc_avg_position,
    sa.total_ranking_keywords, sa.keywords_pos_11_20 AS optimization_targets,
    r.top_competitor_urls, r.competitor_advantages, r.subtopics_with_volume,
    g0.competitor_wc_1, g0.competitor_wc_2, g0.competitor_wc_3,
    g0.competitor_wc_median, a.word_count AS current_word_count,
    g0.wc_delta,
    g0.current_flesch, g0.competitor_flesch_median,
    sa.rps_score, sa.priority_tier,
    r.must_have_updates, r.should_have_updates, r.nice_to_have_updates,
    r.target_keywords, r.ctr_optimization_actions,
    r.traffic_recovery_potential, r.new_traffic_potential,
    r.broken_links, r.redirect_links
FROM risepoint_content.step3_audit.articles sa
JOIN risepoint_content.core.articles a         ON sa.article_id = a.article_id
JOIN risepoint_content.core.programs p         ON a.program_id = p.program_id
LEFT JOIN risepoint_content.step3_audit.recommendations r ON sa.id = r.audit_article_id
LEFT JOIN risepoint_content.step5_refresh.runs rfr         ON rfr.article_id = sa.article_id AND rfr.status = 'in_progress'
LEFT JOIN risepoint_content.step5_refresh.gate0_metrics g0 ON g0.run_id = rfr.run_id;

-- Workflow pipeline status per program
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_workflow_status AS
SELECT
    c.client_name, p.program_name,
    ws.current_phase, ws.current_step, ws.blocking_dependency,
    ws.next_action, ws.last_completed_step, ws.last_completed_date, ws.status
FROM risepoint_content.orchestration.workflow_state ws
JOIN risepoint_content.core.clients c  ON ws.client_id = c.client_id
JOIN risepoint_content.core.programs p ON ws.program_id = p.program_id
ORDER BY ws.updated_at DESC;

-- Keyword coverage map across all audited articles
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_keyword_coverage AS
SELECT
    kr.keyword, kr.volume, kr.kd, kr.position, kr.position_band,
    a.article_url, a.article_title, p.program_name, p.client_id
FROM risepoint_content.step3_audit.keyword_rankings kr
JOIN risepoint_content.core.articles a ON kr.article_id = a.article_id
JOIN risepoint_content.core.programs p ON a.program_id = p.program_id;

-- Keywords with Ahrefs data not yet covered by any ranked article
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_uncovered_keywords AS
SELECT
    ir.keyword, ir.volume, ir.keyword_difficulty AS kd,
    ir.serp_features, p.program_name, p.client_id
FROM risepoint_content.intelligence.ahrefs_organic_keywords ir
JOIN risepoint_content.core.programs p ON ir.target_url LIKE CONCAT('%', p.domain, '%')
LEFT JOIN risepoint_content.step3_audit.keyword_rankings kr ON ir.keyword = kr.keyword
WHERE kr.id IS NULL
  AND ir.volume >= 50
  AND ir.is_current = true
ORDER BY ir.volume DESC;

-- Production throughput and quality metrics per program
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_production_metrics AS
SELECT
    p.program_name, p.client_id,
    COUNT(DISTINCT CASE WHEN sr.status = 'complete' THEN sr.run_id END) AS refreshes_completed,
    AVG(sg1.estimated_change_pct) AS avg_change_pct,
    COUNT(DISTINCT CASE WHEN sc.status = 'complete' THEN sc.run_id END) AS articles_created,
    AVG(sg4.audit9_seo_quality_score) AS avg_seo_quality_score
FROM risepoint_content.core.programs p
LEFT JOIN risepoint_content.step5_refresh.runs sr ON p.program_id = sr.program_id
LEFT JOIN risepoint_content.step5_refresh.gate1_metrics sg1 ON sg1.run_id = sr.run_id
LEFT JOIN risepoint_content.step5_creation.runs sc ON p.program_id = sc.program_id
LEFT JOIN risepoint_content.step5_creation.gate4_results sg4 ON sg4.run_id = sc.run_id
GROUP BY p.program_name, p.client_id;

-- AI Visibility scorecard across all platforms
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_ai_visibility_scorecard AS
SELECT
    ar.brand_name, ar.analysis_mode, ar.run_date,
    ms.platform, ms.total_mentions, ms.solo_mentions,
    is2.total_impressions,
    ss.share_of_voice_pct,
    p.program_name
FROM risepoint_content.ai_visibility.analysis_runs ar
LEFT JOIN risepoint_content.ai_visibility.mention_snapshots ms
       ON ar.run_id = ms.run_id
LEFT JOIN risepoint_content.ai_visibility.impression_snapshots is2
       ON ar.run_id = is2.run_id AND ms.platform = is2.platform AND ms.brand = is2.brand
LEFT JOIN risepoint_content.ai_visibility.sov_snapshots ss
       ON ar.run_id = ss.run_id AND ms.platform = ss.platform AND ms.brand = ss.brand
LEFT JOIN risepoint_content.core.programs p ON ar.program_id = p.program_id
ORDER BY ar.run_date DESC, ms.platform;

-- Cross-program content distribution and anomaly flags
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_cross_program_asymmetry AS
SELECT
    p.program_name,
    COUNT(DISTINCT c.cluster_name)                                            AS cluster_count,
    COUNT(DISTINCT ca.article_id)                                             AS article_count,
    SUM(CASE WHEN ca.is_cross_program THEN 1 ELSE 0 END)                      AS cross_program_articles,
    SUM(CASE WHEN ca.misclassification_target IS NOT NULL THEN 1 ELSE 0 END)  AS misclassified_articles,
    SUM(CASE WHEN ca.is_orphan THEN 1 ELSE 0 END)                             AS orphan_articles
FROM risepoint_content.step1_cluster.article_assignments ca
JOIN risepoint_content.step1_cluster.clusters c ON ca.cluster_id = c.cluster_id
JOIN risepoint_content.core.programs p          ON c.program_id = p.program_id
GROUP BY p.program_name;

-- [OPT-3] 90-day review candidates — articles due for post-publish performance check
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_90day_review_candidates AS
SELECT
    a.article_url, a.article_title, p.program_name, p.client_id,
    h.completed_date, h.run_type,
    h.gate4_score, h.swa_score, h.word_count AS word_count_at_publish,
    h.gsc_position_pre, h.gsc_clicks_pre,
    DATEDIFF(current_date(), h.completed_date) AS days_since_publish
FROM risepoint_content.core.article_production_history h
JOIN risepoint_content.core.articles a ON h.article_id = a.article_id
JOIN risepoint_content.core.programs p ON h.program_id = p.program_id
WHERE h.completed_date <= DATE_SUB(current_date(), 90)
  AND h.completed_date >= DATE_SUB(current_date(), 120)
ORDER BY h.completed_date ASC;

-- [OPT-6] Blocking known issues — agents should query this before executing affected steps
CREATE OR REPLACE VIEW risepoint_content.orchestration.v_blocking_issues AS
SELECT
    issue_id, title, affected_steps, severity,
    description, resolution_notes, opened_date
FROM risepoint_content.orchestration.known_issues
WHERE is_blocking = true AND status != 'resolved'
ORDER BY severity DESC, opened_date ASC;

-- ============================================================================
-- COLUMN DESCRIPTIONS (for Genie Space natural language query accuracy)
-- ============================================================================

-- core
ALTER TABLE risepoint_content.core.clients ALTER COLUMN client_id COMMENT 'Unique client identifier. e.g., fit = Florida Institute of Technology, astate = Arkansas State University, bgsu = Bowling Green State University';
ALTER TABLE risepoint_content.core.programs ALTER COLUMN program_url COMMENT 'Landing page URL — used as seed for Module 0 competitive analysis and program link validation in articles';
ALTER TABLE risepoint_content.core.articles ALTER COLUMN content_age_category COMMENT 'Fresh (0-6mo), Current (6-12mo), Aging (12-24mo), Aging-Extended (24-36mo), Stale (36+mo)';
ALTER TABLE risepoint_content.core.articles ALTER COLUMN status COMMENT 'active = published and live, retired = removed from site, redirect = URL redirected to another, draft = not yet published, planned = in content calendar';

-- step3_audit
ALTER TABLE risepoint_content.step3_audit.articles ALTER COLUMN gsc_clicks_90d COMMENT 'Actual user clicks from Google Search Console — ground truth. Ahrefs estimates are supplemental and can overestimate 3-15x.';
ALTER TABLE risepoint_content.step3_audit.articles ALTER COLUMN ahrefs_traffic_estimate COMMENT 'Ahrefs estimated traffic — informational only. Compare to gsc_monthly_clicks for actual performance.';
ALTER TABLE risepoint_content.step3_audit.articles ALTER COLUMN rps_score COMMENT 'Refresh Priority Score 0-10. Critical >= 8.0, High 6.0-7.9, Medium 4.0-5.9, Low 2.0-3.9, Healthy 0-1.9. Route A threshold = 6.0.';
ALTER TABLE risepoint_content.step3_audit.articles ALTER COLUMN routing_decision COMMENT 'Route A = refresh existing article, Route B = retire and redirect, Route C = replace with new article, Monitor = no action needed';
ALTER TABLE risepoint_content.step3_audit.keyword_opportunities ALTER COLUMN competitive_priority COMMENT 'HIGH requires volume >= 500 AND KD <= 40. KD > 40 = MEDIUM regardless of volume. This rule is enforced by ARID14 v1.6.';

-- step5_refresh [OPT-1]
ALTER TABLE risepoint_content.step5_refresh.runs ALTER COLUMN prompt_version COMMENT 'Must be 2.1 (live file) not 2.0 (config registry) until KI-02 is resolved. Mismatch here indicates automation was built against wrong config.';
ALTER TABLE risepoint_content.step5_refresh.gate2_metrics ALTER COLUMN feedback_loop_triggered COMMENT 'true = Source-Constrained section returned to Gate 1 — this is a designed recovery loop, not a failure state';
ALTER TABLE risepoint_content.step5_refresh.gate1_metrics ALTER COLUMN five_source_minimum COMMENT 'true = source minimum elevated from standard to 5 because estimated_change_pct > 30. Activates Gate 2 stricter sourcing requirement.';

-- step5_creation [OPT-2]
ALTER TABLE risepoint_content.step5_creation.gate4_results ALTER COLUMN audit9_seo_quality_score COMMENT 'SEO Quality Score on 10-point scale. Pass threshold = 8.0. Score 6.5-7.9 surfaces to editor. Score < 6.5 auto-iterates back to Draft Agent.';

-- orchestration [OPT-3, OPT-4, OPT-6]
ALTER TABLE risepoint_content.core.article_production_history ALTER COLUMN gsc_position_pre COMMENT 'GSC average position captured immediately before this production run. Required by 90-Day Review Agent to calculate performance delta.';
ALTER TABLE risepoint_content.orchestration.artifacts ALTER COLUMN confluence_page_id COMMENT 'Confluence page ID returned by Atlassian MCP createConfluencePage. Use with Atlassian MCP get_page for programmatic retrieval. Required for all markdown artifacts published to Confluence.';
ALTER TABLE risepoint_content.orchestration.artifacts ALTER COLUMN sharepoint_item_id COMMENT 'Microsoft Graph drive item ID returned by Graph API file upload. Use with GET /drives/{drive-id}/items/{item-id}/content for retrieval. Required for all binary files (.docx, .xlsx) published to SharePoint.';
ALTER TABLE risepoint_content.orchestration.known_issues ALTER COLUMN is_blocking COMMENT 'true = agents MUST halt before executing affected_steps and surface this issue to the operator. false = advisory only.';

-- ============================================================================
-- DONE
-- 64 tables (was 53 in v2.0) + 12 views (was 9) across 11 schemas
--
-- Net additions vs v2.0:
--   +1  core.article_production_history          [OPT-3]
--   +6  step5_refresh gate detail tables         [OPT-1]  (-1 fat table, +7 normalized)
--   +4  step5_creation detail tables             [OPT-2]  (-1 fat table, +5 normalized)
--   +1  orchestration.known_issues               [OPT-6]
--   +3  views (v_90day_review_candidates,        [OPT-3, OPT-6]
--              v_blocking_issues,
--              updated v_prework_package)
-- ============================================================================
