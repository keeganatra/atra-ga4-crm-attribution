-- ATRA QA 01: Record Uniqueness
-- Replace project/dataset placeholders before running.

-- CRM clean layer should be one row per CRM record.
SELECT
  'crm_leads_clean' AS test_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT crm_record_id) AS distinct_record_count,
  COUNT(*) - COUNT(DISTINCT crm_record_id) AS duplicate_rows
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`;

-- Lead summary MUST be one row per CRM record.
SELECT
  'lead_summary' AS test_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT crm_record_id) AS distinct_record_count,
  COUNT(*) - COUNT(DISTINCT crm_record_id) AS duplicate_rows
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.lead_summary`;

-- Show offending IDs if the CRM clean layer is not unique.
SELECT
  crm_record_id,
  COUNT(*) AS row_count
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`
GROUP BY crm_record_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 100;
