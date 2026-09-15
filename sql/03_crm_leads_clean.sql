-- =========================================================
-- ATRA GA4 + CRM Attribution
-- 03) CRM LEADS CLEAN
-- Intended grain: one row per CRM attribution record / lead
-- =========================================================
--
-- PURPOSE
-- Create a stable, CRM-agnostic interface between the source CRM
-- and the downstream attribution model. This is the SQL file that
-- normally requires the most customization for a new implementation.
--
-- IMPORTANT
-- Replace every YOUR_* placeholder below with the corresponding
-- field from the organization's CRM source table.
--
-- IDENTITY REQUIREMENT
-- YOUR_GA_VISITOR_ID_FIELD must contain the GA4 Client ID / visitor
-- identifier captured on the website and stored in the CRM. After
-- cleaning, crm_ga_join_id should match GA4 user_pseudo_id.
--
-- YOUR_GA_SESSION_ID_FIELD should contain the GA4 Session ID captured
-- at form submission. Preserve it as text. It is not a replacement for
-- the Client ID; it identifies the exact conversion session.
--
-- DEDUPLICATION
-- The source should resolve to one row per YOUR_CRM_RECORD_ID_FIELD.
-- If the CRM warehouse contains history/version rows, add the source-
-- appropriate deduplication logic here before deploying downstream.
-- =========================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean` AS
SELECT
  -- Required record identity.
  YOUR_CRM_RECORD_ID_FIELD AS crm_record_id,

  -- Default lead milestone.
  YOUR_LEAD_CREATED_DATETIME_FIELD AS crm_lead_created_datetime,
  TIMESTAMP(YOUR_LEAD_CREATED_DATETIME_FIELD, 'YOUR_TIMEZONE') AS crm_lead_created_timestamp,

  -- Default downstream outcome. If your CRM stores a timestamp rather
  -- than a date, adapt this field and the downstream sale logic.
  YOUR_SALE_DATE_FIELD AS crm_sale_date,

  CASE
    WHEN YOUR_SALE_DATE_FIELD IS NOT NULL THEN 1
    ELSE 0
  END AS crm_is_sold,

  -- GA4 identity captured in the CRM.
  YOUR_GA_VISITOR_ID_FIELD AS crm_ga_visitor_id_raw,
  TRIM(LOWER(CAST(YOUR_GA_VISITOR_ID_FIELD AS STRING))) AS crm_ga_visitor_id_trimmed,
  REGEXP_REPLACE(
    TRIM(LOWER(CAST(YOUR_GA_VISITOR_ID_FIELD AS STRING))),
    r'^ga_?',
    ''
  ) AS crm_ga_join_id,
  CAST(YOUR_GA_SESSION_ID_FIELD AS STRING) AS crm_ga_session_id,

  -- Recommended reporting dimensions. Map these to equivalent CRM
  -- fields or remove fields that do not exist in your implementation.
  YOUR_LEAD_SOURCE_FIELD AS crm_lead_source,
  YOUR_CAMPAIGN_ID_FIELD AS crm_campaign_id,
  YOUR_CAMPAIGN_NAME_FIELD AS crm_campaign_name,
  YOUR_CRM_TOUCH_COUNT_FIELD AS crm_reported_touch_count,

  -- Optional click / platform identifiers.
  YOUR_GOOGLE_CLICK_ID_FIELD AS crm_google_click_id,
  YOUR_MICROSOFT_CLICK_ID_FIELD AS crm_microsoft_click_id,
  YOUR_META_LEAD_ID_FIELD AS crm_meta_lead_id,

  -- Example optional segmentation dimensions.
  YOUR_AGE_FIELD AS crm_age,
  YOUR_GENDER_FIELD AS crm_gender,

  -- Example custom fields. Rename these to meaningful business names
  -- during implementation whenever possible.
  YOUR_CUSTOM_FIELD_01 AS crm_custom_01,
  YOUR_CUSTOM_FIELD_02 AS crm_custom_02,
  YOUR_CUSTOM_FIELD_03 AS crm_custom_03,
  YOUR_CUSTOM_FIELD_04 AS crm_custom_04,
  YOUR_CUSTOM_FIELD_05 AS crm_custom_05

FROM `YOUR_PROJECT_ID.YOUR_CRM_DATASET.YOUR_CRM_SOURCE_TABLE`;

-- =========================================================
-- REQUIRED VALIDATION AFTER BUILD
-- This query should return zero rows before proceeding.
-- =========================================================
-- SELECT crm_record_id, COUNT(*) AS row_count
-- FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean`
-- GROUP BY crm_record_id
-- HAVING COUNT(*) > 1;
