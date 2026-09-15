-- ATRA QA 03: CRM Outcome Reconciliation
-- Compare the clean CRM layer and final reporting layer. These counts
-- should reconcile before Data Studio reporting is approved.

SELECT
  'crm_leads_clean' AS table_name,
  COUNT(*) AS records,
  COUNTIF(crm_is_sold = 1) AS sold_records
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`

UNION ALL

SELECT
  'lead_summary' AS table_name,
  COUNT(*) AS records,
  COUNTIF(crm_is_sold = 1) AS sold_records
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.lead_summary`;

-- Also reconcile these values against the source CRM using the exact
-- business definition selected for lead and sale milestones.
