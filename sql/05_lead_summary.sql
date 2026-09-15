-- =========================================================
-- ATRA GA4 + CRM Attribution
-- 05) LEAD SUMMARY
-- Grain: exactly one row per crm_record_id
-- =========================================================
--
-- PURPOSE
-- Collapse the session-level journey into a reporting-friendly CRM
-- record. Produces first/last touch, channel paths, session counts,
-- and time-to-conversion metrics.
--
-- DEFAULT ATTRIBUTION OUTPUTS
-- - First touch before lead
-- - Last touch before lead
-- - First touch before sale
-- - Last touch before sale
-- - Full channel path before lead
-- - Full channel path before sale
-- - Sessions before each milestone
-- - Time from first observed GA4 session to each milestone
-- =========================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.lead_summary` AS
SELECT *
FROM (
  WITH base AS (
    SELECT *
    FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.journey_sessions`
  ),

  first_visit AS (
    SELECT
      crm_record_id,
      MIN(ga_session_start_timestamp_utc) AS ga_first_session_timestamp_utc
    FROM base
    WHERE ga_session_id IS NOT NULL
    GROUP BY crm_record_id
  ),

  all_session_counts AS (
    SELECT
      crm_record_id,
      COUNT(DISTINCT ga_session_id) AS ga_total_sessions
    FROM base
    WHERE ga_session_id IS NOT NULL
    GROUP BY crm_record_id
  ),

  pre_lead_paths AS (
    SELECT
      crm_record_id,
      COUNT(DISTINCT ga_session_id) AS ga_sessions_before_lead,
      STRING_AGG(
        COALESCE(
          ga_default_channel_group,
          CONCAT(COALESCE(ga_source, '(direct)'), ' / ', COALESCE(ga_medium, '(none)'))
        ),
        ' > '
        ORDER BY ga_session_start_timestamp_utc
      ) AS ga_path_before_lead
    FROM base
    WHERE ga_is_pre_lead_session = 1
      AND ga_session_id IS NOT NULL
    GROUP BY crm_record_id
  ),

  pre_sale_paths AS (
    SELECT
      crm_record_id,
      COUNT(DISTINCT ga_session_id) AS ga_sessions_before_sale,
      STRING_AGG(
        COALESCE(
          ga_default_channel_group,
          CONCAT(COALESCE(ga_source, '(direct)'), ' / ', COALESCE(ga_medium, '(none)'))
        ),
        ' > '
        ORDER BY ga_session_start_timestamp_utc
      ) AS ga_path_before_sale
    FROM base
    WHERE ga_is_pre_sale_session = 1
      AND ga_session_id IS NOT NULL
    GROUP BY crm_record_id
  ),

  pre_lead_ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY crm_record_id
        ORDER BY ga_session_start_timestamp_utc ASC
      ) AS ga_rn_first_pre_lead,
      ROW_NUMBER() OVER (
        PARTITION BY crm_record_id
        ORDER BY ga_session_start_timestamp_utc DESC
      ) AS ga_rn_last_pre_lead
    FROM base
    WHERE ga_is_pre_lead_session = 1
      AND ga_session_id IS NOT NULL
  ),

  pre_sale_ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY crm_record_id
        ORDER BY ga_session_start_timestamp_utc ASC
      ) AS ga_rn_first_pre_sale,
      ROW_NUMBER() OVER (
        PARTITION BY crm_record_id
        ORDER BY ga_session_start_timestamp_utc DESC
      ) AS ga_rn_last_pre_sale
    FROM base
    WHERE ga_is_pre_sale_session = 1
      AND ga_session_id IS NOT NULL
  ),

  crm_core AS (
    SELECT DISTINCT
      crm_record_id,
      crm_lead_created_datetime,
      crm_lead_created_timestamp,
      crm_sale_date,
      crm_is_sold,
      crm_ga_visitor_id_raw,
      crm_ga_visitor_id_trimmed,
      crm_ga_join_id,
      crm_lead_source,
      crm_campaign_id,
      crm_campaign_name,
      crm_reported_touch_count,
      crm_google_click_id,
      crm_microsoft_click_id,
      crm_meta_lead_id,
      crm_age,
      crm_gender,
      crm_custom_01,
      crm_custom_02,
      crm_custom_03,
      crm_custom_04,
      crm_custom_05
    FROM base
  )

  SELECT
    crm.*,

    fv.ga_first_session_timestamp_utc,
    DATETIME(fv.ga_first_session_timestamp_utc, 'YOUR_TIMEZONE') AS ga_first_session_datetime_local,

    TIMESTAMP_DIFF(
      crm.crm_lead_created_timestamp,
      fv.ga_first_session_timestamp_utc,
      DAY
    ) AS ga_days_to_lead,

    TIMESTAMP_DIFF(
      crm.crm_lead_created_timestamp,
      fv.ga_first_session_timestamp_utc,
      HOUR
    ) AS ga_hours_to_lead,

    -- Sale is a DATE in the default template. End-of-day is used only
    -- to create an approximate timestamp for hour/day differences.
    -- Exact time-to-sale requires an exact CRM sale timestamp.
    CASE
      WHEN crm.crm_sale_date IS NOT NULL THEN
        TIMESTAMP_DIFF(
          TIMESTAMP(DATETIME(crm.crm_sale_date, TIME '23:59:59'), 'YOUR_TIMEZONE'),
          fv.ga_first_session_timestamp_utc,
          DAY
        )
      ELSE NULL
    END AS ga_days_to_sale,

    CASE
      WHEN crm.crm_sale_date IS NOT NULL THEN
        TIMESTAMP_DIFF(
          TIMESTAMP(DATETIME(crm.crm_sale_date, TIME '23:59:59'), 'YOUR_TIMEZONE'),
          fv.ga_first_session_timestamp_utc,
          HOUR
        )
      ELSE NULL
    END AS ga_hours_to_sale,

    ascnt.ga_total_sessions,
    plp.ga_sessions_before_lead,
    psp.ga_sessions_before_sale,
    plp.ga_path_before_lead,
    psp.ga_path_before_sale,

    -- First / last touch before lead.
    fpl.ga_session_start_timestamp_utc AS ga_first_touch_pre_lead_timestamp_utc,
    DATETIME(fpl.ga_session_start_timestamp_utc, 'YOUR_TIMEZONE') AS ga_first_touch_pre_lead_datetime_local,
    fpl.ga_source AS ga_first_touch_pre_lead_source,
    fpl.ga_medium AS ga_first_touch_pre_lead_medium,
    fpl.ga_campaign AS ga_first_touch_pre_lead_campaign,
    fpl.ga_default_channel_group AS ga_first_touch_pre_lead_channel_group,

    lpl.ga_session_start_timestamp_utc AS ga_last_touch_pre_lead_timestamp_utc,
    DATETIME(lpl.ga_session_start_timestamp_utc, 'YOUR_TIMEZONE') AS ga_last_touch_pre_lead_datetime_local,
    lpl.ga_source AS ga_last_touch_pre_lead_source,
    lpl.ga_medium AS ga_last_touch_pre_lead_medium,
    lpl.ga_campaign AS ga_last_touch_pre_lead_campaign,
    lpl.ga_default_channel_group AS ga_last_touch_pre_lead_channel_group,

    -- First / last touch before sale.
    fps.ga_session_start_timestamp_utc AS ga_first_touch_pre_sale_timestamp_utc,
    DATETIME(fps.ga_session_start_timestamp_utc, 'YOUR_TIMEZONE') AS ga_first_touch_pre_sale_datetime_local,
    fps.ga_source AS ga_first_touch_pre_sale_source,
    fps.ga_medium AS ga_first_touch_pre_sale_medium,
    fps.ga_campaign AS ga_first_touch_pre_sale_campaign,
    fps.ga_default_channel_group AS ga_first_touch_pre_sale_channel_group,

    lps.ga_session_start_timestamp_utc AS ga_last_touch_pre_sale_timestamp_utc,
    DATETIME(lps.ga_session_start_timestamp_utc, 'YOUR_TIMEZONE') AS ga_last_touch_pre_sale_datetime_local,
    lps.ga_source AS ga_last_touch_pre_sale_source,
    lps.ga_medium AS ga_last_touch_pre_sale_medium,
    lps.ga_campaign AS ga_last_touch_pre_sale_campaign,
    lps.ga_default_channel_group AS ga_last_touch_pre_sale_channel_group

  FROM crm_core crm
  LEFT JOIN first_visit fv USING (crm_record_id)
  LEFT JOIN all_session_counts ascnt USING (crm_record_id)
  LEFT JOIN pre_lead_paths plp USING (crm_record_id)
  LEFT JOIN pre_sale_paths psp USING (crm_record_id)
  LEFT JOIN (
    SELECT * FROM pre_lead_ranked WHERE ga_rn_first_pre_lead = 1
  ) fpl USING (crm_record_id)
  LEFT JOIN (
    SELECT * FROM pre_lead_ranked WHERE ga_rn_last_pre_lead = 1
  ) lpl USING (crm_record_id)
  LEFT JOIN (
    SELECT * FROM pre_sale_ranked WHERE ga_rn_first_pre_sale = 1
  ) fps USING (crm_record_id)
  LEFT JOIN (
    SELECT * FROM pre_sale_ranked WHERE ga_rn_last_pre_sale = 1
  ) lps USING (crm_record_id)
)
-- Safety guard: the reporting table must remain one row per CRM record.
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY crm_record_id
  ORDER BY ga_first_session_timestamp_utc
) = 1;
