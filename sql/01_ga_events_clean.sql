-- =========================================================
-- ATRA GA4 + CRM Attribution
-- 01) GA EVENTS CLEAN
-- Grain: one row per GA4 event
-- =========================================================
--
-- PURPOSE
-- Standardize the raw GA4 BigQuery daily export and extract
-- commonly needed nested fields into analysis-friendly columns.
--
-- REQUIRED CUSTOMIZATION
-- 1. Replace YOUR_PROJECT_ID.
-- 2. Replace YOUR_GA4_DATASET (normally analytics_PROPERTYID).
-- 3. Replace YOUR_ATTRIBUTION_DATASET.
-- 4. Replace YOUR_TIMEZONE with an IANA timezone such as
--    America/New_York.
--
-- NOTE
-- This intentionally prioritizes readability over incremental
-- processing. It rebuilds from all available daily GA4 tables.
-- =========================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_events_clean` AS
WITH source_events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS ga_event_date,
    TIMESTAMP_MICROS(event_timestamp) AS ga_event_timestamp_utc,
    DATETIME(TIMESTAMP_MICROS(event_timestamp), 'YOUR_TIMEZONE') AS ga_event_datetime_local,
    event_timestamp AS ga_event_timestamp_micros,
    event_name AS ga_event_name,

    TRIM(LOWER(user_pseudo_id)) AS ga_user_pseudo_id,
    user_id AS ga_user_id,

    TIMESTAMP_MICROS(user_first_touch_timestamp) AS ga_user_first_touch_timestamp_utc,
    DATETIME(TIMESTAMP_MICROS(user_first_touch_timestamp), 'YOUR_TIMEZONE') AS ga_user_first_touch_datetime_local,

    -- Standard GA4 session identifiers are stored in event_params.
    (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1
    ) AS ga_session_id,

    (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_number'
      LIMIT 1
    ) AS ga_session_number,

    (
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1
    ) AS ga_page_location,

    (
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_referrer'
      LIMIT 1
    ) AS ga_page_referrer,

    -- Preserve raw nested structures for future customization.
    event_params AS ga_event_params,
    device AS ga_device,
    traffic_source AS ga_traffic_source,
    ecommerce AS ga_ecommerce,
    session_traffic_source_last_click AS ga_session_traffic_source_last_click,
    collected_traffic_source AS ga_collected_traffic_source,

    -- Device / geography.
    device.category AS ga_device_category,
    device.operating_system AS ga_device_operating_system,
    device.web_info.browser AS ga_browser,
    device.web_info.browser_version AS ga_browser_version,
    device.web_info.hostname AS ga_hostname,
    geo.country AS ga_geo_country,
    geo.region AS ga_geo_region,
    geo.city AS ga_geo_city,
    platform AS ga_platform,

    -- First-user acquisition fields. These describe user acquisition,
    -- not necessarily the source of the current session.
    traffic_source.source AS ga_first_user_source,
    traffic_source.medium AS ga_first_user_medium,
    traffic_source.name AS ga_first_user_campaign,

    -- Collected traffic fields.
    collected_traffic_source.manual_source AS ga_manual_source,
    collected_traffic_source.manual_medium AS ga_manual_medium,
    collected_traffic_source.manual_campaign_name AS ga_manual_campaign,
    collected_traffic_source.gclid AS ga_gclid,
    collected_traffic_source.dclid AS ga_dclid,
    collected_traffic_source.srsltid AS ga_srsltid,

    -- Session last-click traffic fields.
    session_traffic_source_last_click.manual_campaign.source AS ga_stslc_manual_source,
    session_traffic_source_last_click.manual_campaign.medium AS ga_stslc_manual_medium,
    session_traffic_source_last_click.manual_campaign.campaign_name AS ga_stslc_manual_campaign,

    session_traffic_source_last_click.cross_channel_campaign.source AS ga_stslc_cross_source,
    session_traffic_source_last_click.cross_channel_campaign.medium AS ga_stslc_cross_medium,
    session_traffic_source_last_click.cross_channel_campaign.campaign_name AS ga_stslc_cross_campaign,
    session_traffic_source_last_click.cross_channel_campaign.default_channel_group AS ga_default_channel_group,
    session_traffic_source_last_click.cross_channel_campaign.primary_channel_group AS ga_primary_channel_group,

    -- Ecommerce fields are optional but useful for organizations that
    -- also want transaction context available downstream.
    ecommerce.transaction_id AS ga_ecommerce_transaction_id,
    ecommerce.purchase_revenue AS ga_ecommerce_purchase_revenue,
    ecommerce.purchase_revenue_in_usd AS ga_ecommerce_purchase_revenue_usd

  FROM `YOUR_PROJECT_ID.YOUR_GA4_DATASET.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX <= FORMAT_DATE('%Y%m%d', CURRENT_DATE('YOUR_TIMEZONE'))
)
SELECT *
FROM source_events
WHERE ga_user_pseudo_id IS NOT NULL;
