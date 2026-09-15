-- =========================================================
-- ATRA GA4 + CRM Attribution
-- 04) JOURNEY SESSIONS
-- Grain: one row per CRM record + matched GA4 session
-- =========================================================
--
-- PURPOSE
-- Join CRM outcomes to all known GA4 sessions for the same visitor,
-- then classify sessions according to whether they occurred before
-- the lead milestone and downstream sale milestone.
--
-- REPORTING WARNING
-- This is a one-to-many journey table. Do not sum lead/sale counts
-- from this table without deduplicating to crm_record_id.
-- =========================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.journey_sessions` AS
SELECT
  -- CRM record and milestones.
  crm.crm_record_id,
  crm.crm_lead_created_datetime,
  crm.crm_lead_created_timestamp,
  crm.crm_sale_date,
  crm.crm_is_sold,

  -- CRM identity and dimensions.
  crm.crm_ga_visitor_id_raw,
  crm.crm_ga_visitor_id_trimmed,
  crm.crm_ga_join_id,
  crm.crm_ga_session_id,
  crm.crm_lead_source,
  crm.crm_campaign_id,
  crm.crm_campaign_name,
  crm.crm_reported_touch_count,
  crm.crm_google_click_id,
  crm.crm_microsoft_click_id,
  crm.crm_meta_lead_id,
  crm.crm_age,
  crm.crm_gender,
  crm.crm_custom_01,
  crm.crm_custom_02,
  crm.crm_custom_03,
  crm.crm_custom_04,
  crm.crm_custom_05,

  -- GA4 session.
  gs.ga_user_pseudo_id,
  gs.ga_session_id,
  gs.ga_session_number,
  gs.ga_session_start_timestamp_utc,
  gs.ga_session_start_datetime_local,
  gs.ga_session_start_date_local,
  gs.ga_session_end_timestamp_utc,
  gs.ga_session_end_datetime_local,
  gs.ga_device_category,
  gs.ga_device_operating_system,
  gs.ga_browser,
  gs.ga_browser_version,
  gs.ga_hostname,
  gs.ga_geo_country,
  gs.ga_geo_region,
  gs.ga_geo_city,
  gs.ga_platform,
  gs.ga_source,
  gs.ga_medium,
  gs.ga_campaign,
  gs.ga_default_channel_group,
  gs.ga_primary_channel_group,
  gs.ga_event_count,
  gs.ga_event_names,
  gs.ga_page_locations,
  gs.ga_has_gclid,
  gs.ga_has_dclid,
  gs.ga_ecommerce_transaction_id,
  gs.ga_ecommerce_purchase_revenue,
  gs.ga_ecommerce_purchase_revenue_usd,

  -- Exact conversion-session validation. Client ID remains the journey join;
  -- the captured Session ID identifies which matched session submitted the form.
  CASE
    WHEN crm.crm_ga_session_id IS NOT NULL
      AND CAST(gs.ga_session_id AS STRING) = crm.crm_ga_session_id
    THEN 1
    ELSE 0
  END AS ga_is_captured_conversion_session,

  -- Default lead-window classification.
  CASE
    WHEN gs.ga_session_start_timestamp_utc <= crm.crm_lead_created_timestamp THEN 1
    ELSE 0
  END AS ga_is_pre_lead_session,

  -- Default sale-window classification.
  -- Because the default template assumes sale is a DATE rather than a
  -- timestamp, all sessions occurring on or before the sale date are
  -- considered pre-sale. If the CRM has an exact sale timestamp, use it.
  CASE
    WHEN crm.crm_sale_date IS NOT NULL
      AND DATE(DATETIME(gs.ga_session_start_timestamp_utc, 'YOUR_TIMEZONE')) <= crm.crm_sale_date
    THEN 1
    ELSE 0
  END AS ga_is_pre_sale_session

FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.crm_leads_clean` crm
LEFT JOIN `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_sessions_clean` gs
  ON crm.crm_ga_join_id = gs.ga_user_pseudo_id;
