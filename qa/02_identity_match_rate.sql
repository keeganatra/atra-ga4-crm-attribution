-- ATRA QA 02: GA4 <-> CRM Identity Match Rate
-- Understand how much of the CRM population can actually be joined
-- to observed GA4 behavior. A low rate is not automatically a SQL
-- failure; it may indicate missing Client ID capture, consent effects,
-- cross-device behavior, or historical CRM records predating tracking.

WITH crm AS (
  SELECT
    crm_record_id,
    crm_ga_join_id
  FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`
),
ga_users AS (
  SELECT DISTINCT ga_user_pseudo_id
  FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_sessions_clean`
)
SELECT
  COUNT(*) AS crm_records,
  COUNTIF(crm_ga_join_id IS NOT NULL AND crm_ga_join_id != '') AS crm_records_with_ga_id,
  COUNTIF(ga_user_pseudo_id IS NOT NULL) AS matched_crm_records,
  SAFE_DIVIDE(
    COUNTIF(ga_user_pseudo_id IS NOT NULL),
    COUNT(*)
  ) AS overall_match_rate,
  SAFE_DIVIDE(
    COUNTIF(ga_user_pseudo_id IS NOT NULL),
    COUNTIF(crm_ga_join_id IS NOT NULL AND crm_ga_join_id != '')
  ) AS match_rate_when_ga_id_present
FROM crm
LEFT JOIN ga_users
  ON crm.crm_ga_join_id = ga_users.ga_user_pseudo_id;
