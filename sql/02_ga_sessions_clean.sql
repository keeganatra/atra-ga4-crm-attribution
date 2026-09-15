-- =========================================================
-- ATRA GA4 + CRM Attribution
-- 02) GA SESSIONS CLEAN
-- Grain: one row per GA4 user + session
-- =========================================================
--
-- PURPOSE
-- Collapse event-level GA4 activity into an analysis-friendly
-- session layer. A session is the default journey unit in V1.
--
-- REQUIRED CUSTOMIZATION
-- 1. Replace YOUR_PROJECT_ID.
-- 2. Replace YOUR_ATTRIBUTION_DATASET.
-- 3. Replace YOUR_TIMEZONE.
--
-- ATTRIBUTION NOTE
-- Session source/medium/campaign use a readable precedence:
-- cross-channel session attribution -> manual session attribution
-- -> collected traffic -> first-user acquisition fallback.
-- Organizations may replace this precedence with their own rules.
-- =========================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_sessions_clean` AS
WITH sessionized AS (
  SELECT
    ga_user_pseudo_id,
    ga_session_id,
    ga_session_number,

    MIN(ga_event_timestamp_utc) AS ga_session_start_timestamp_utc,
    DATETIME(MIN(ga_event_timestamp_utc), 'YOUR_TIMEZONE') AS ga_session_start_datetime_local,
    DATE(DATETIME(MIN(ga_event_timestamp_utc), 'YOUR_TIMEZONE')) AS ga_session_start_date_local,

    MAX(ga_event_timestamp_utc) AS ga_session_end_timestamp_utc,
    DATETIME(MAX(ga_event_timestamp_utc), 'YOUR_TIMEZONE') AS ga_session_end_datetime_local,

    ANY_VALUE(ga_device_category) AS ga_device_category,
    ANY_VALUE(ga_device_operating_system) AS ga_device_operating_system,
    ANY_VALUE(ga_browser) AS ga_browser,
    ANY_VALUE(ga_browser_version) AS ga_browser_version,
    ANY_VALUE(ga_hostname) AS ga_hostname,
    ANY_VALUE(ga_geo_country) AS ga_geo_country,
    ANY_VALUE(ga_geo_region) AS ga_geo_region,
    ANY_VALUE(ga_geo_city) AS ga_geo_city,
    ANY_VALUE(ga_platform) AS ga_platform,

    COALESCE(
      ANY_VALUE(ga_stslc_cross_source),
      ANY_VALUE(ga_stslc_manual_source),
      ANY_VALUE(ga_manual_source),
      ANY_VALUE(ga_first_user_source)
    ) AS ga_source,

    COALESCE(
      ANY_VALUE(ga_stslc_cross_medium),
      ANY_VALUE(ga_stslc_manual_medium),
      ANY_VALUE(ga_manual_medium),
      ANY_VALUE(ga_first_user_medium)
    ) AS ga_medium,

    COALESCE(
      ANY_VALUE(ga_stslc_cross_campaign),
      ANY_VALUE(ga_stslc_manual_campaign),
      ANY_VALUE(ga_manual_campaign),
      ANY_VALUE(ga_first_user_campaign)
    ) AS ga_campaign,

    ANY_VALUE(ga_default_channel_group) AS ga_default_channel_group,
    ANY_VALUE(ga_primary_channel_group) AS ga_primary_channel_group,

    COUNT(*) AS ga_event_count,
    ARRAY_AGG(DISTINCT ga_event_name IGNORE NULLS ORDER BY ga_event_name) AS ga_event_names,
    ARRAY_AGG(DISTINCT ga_page_location IGNORE NULLS LIMIT 25) AS ga_page_locations,

    MAX(CASE WHEN ga_gclid IS NOT NULL THEN 1 ELSE 0 END) AS ga_has_gclid,
    MAX(CASE WHEN ga_dclid IS NOT NULL THEN 1 ELSE 0 END) AS ga_has_dclid,

    MAX(ga_ecommerce_transaction_id) AS ga_ecommerce_transaction_id,
    MAX(ga_ecommerce_purchase_revenue) AS ga_ecommerce_purchase_revenue,
    MAX(ga_ecommerce_purchase_revenue_usd) AS ga_ecommerce_purchase_revenue_usd

  FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_events_clean`
  WHERE ga_session_id IS NOT NULL
  GROUP BY
    ga_user_pseudo_id,
    ga_session_id,
    ga_session_number
)
SELECT *
FROM sessionized;
