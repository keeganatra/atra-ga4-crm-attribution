-- ATRA QA 02: GA4 <-> CRM Identity + Conversion Session Match Rate
-- Measures both browser-level identity matching and exact conversion-session matching.
-- Client ID remains the primary historical journey key. Session ID is a secondary
-- validation key identifying the session that produced the CRM record.

WITH crm AS (
  SELECT
    crm_record_id,
    crm_ga_join_id,
    crm_ga_session_id
  FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`
),
ga_sessions AS (
  SELECT DISTINCT
    ga_user_pseudo_id,
    CAST(ga_session_id AS STRING) AS ga_session_id
  FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_sessions_clean`
),
joined AS (
  SELECT
    crm.*,
    ga.ga_user_pseudo_id,
    ga.ga_session_id,
    CASE
      WHEN ga.ga_user_pseudo_id IS NOT NULL THEN 1 ELSE 0
    END AS has_user_match,
    CASE
      WHEN ga.ga_user_pseudo_id IS NOT NULL
        AND crm.crm_ga_session_id IS NOT NULL
        AND ga.ga_session_id = crm.crm_ga_session_id
      THEN 1 ELSE 0
    END AS has_exact_session_match
  FROM crm
  LEFT JOIN ga_sessions ga
    ON crm.crm_ga_join_id = ga.ga_user_pseudo_id
),
record_level AS (
  SELECT
    crm_record_id,
    MAX(CASE WHEN crm_ga_join_id IS NOT NULL AND crm_ga_join_id != '' THEN 1 ELSE 0 END) AS has_client_id,
    MAX(CASE WHEN crm_ga_session_id IS NOT NULL AND crm_ga_session_id != '' THEN 1 ELSE 0 END) AS has_session_id,
    MAX(has_user_match) AS has_user_match,
    MAX(has_exact_session_match) AS has_exact_session_match
  FROM joined
  GROUP BY crm_record_id
)
SELECT
  COUNT(*) AS crm_records,
  COUNTIF(has_client_id = 1) AS crm_records_with_client_id,
  COUNTIF(has_session_id = 1) AS crm_records_with_session_id,
  COUNTIF(has_user_match = 1) AS matched_crm_records,
  COUNTIF(has_exact_session_match = 1) AS exact_conversion_session_matches,
  SAFE_DIVIDE(COUNTIF(has_user_match = 1), COUNT(*)) AS overall_client_id_match_rate,
  SAFE_DIVIDE(
    COUNTIF(has_user_match = 1),
    COUNTIF(has_client_id = 1)
  ) AS client_id_match_rate_when_present,
  SAFE_DIVIDE(
    COUNTIF(has_exact_session_match = 1),
    COUNTIF(has_session_id = 1)
  ) AS conversion_session_match_rate_when_session_id_present
FROM record_level;
