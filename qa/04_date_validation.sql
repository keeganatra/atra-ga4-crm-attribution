-- ATRA QA 04: Date and Milestone Validation

SELECT
  MIN(ga_event_date) AS earliest_ga_event_date,
  MAX(ga_event_date) AS latest_ga_event_date
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_events_clean`;

SELECT
  MIN(DATE(crm_lead_created_timestamp, 'YOUR_TIMEZONE')) AS earliest_lead_date,
  MAX(DATE(crm_lead_created_timestamp, 'YOUR_TIMEZONE')) AS latest_lead_date,
  MIN(crm_sale_date) AS earliest_sale_date,
  MAX(crm_sale_date) AS latest_sale_date
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`;

-- Sessions marked pre-lead should never start after the lead timestamp.
SELECT COUNT(*) AS invalid_pre_lead_sessions
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.journey_sessions`
WHERE ga_is_pre_lead_session = 1
  AND ga_session_start_timestamp_utc > crm_lead_created_timestamp;

-- Negative time-to-lead values can indicate identity reuse, CRM timing
-- issues, or incorrect milestone/timezone logic and should be reviewed.
SELECT COUNT(*) AS records_with_negative_days_to_lead
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.lead_summary`
WHERE ga_days_to_lead < 0;
