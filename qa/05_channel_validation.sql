-- ATRA QA 05: Channel / Traffic Quality
-- Review these distributions before building attribution reporting.

SELECT
  COALESCE(ga_default_channel_group, '(null)') AS ga_default_channel_group,
  COUNT(*) AS sessions,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) AS session_share
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_sessions_clean`
GROUP BY ga_default_channel_group
ORDER BY sessions DESC;

SELECT
  COUNT(*) AS total_sessions,
  COUNTIF(ga_default_channel_group IS NULL) AS null_channel_sessions,
  COUNTIF(LOWER(COALESCE(ga_default_channel_group, '')) = 'unassigned') AS unassigned_sessions,
  COUNTIF(ga_source IS NULL) AS null_source_sessions,
  COUNTIF(ga_medium IS NULL) AS null_medium_sessions,
  SAFE_DIVIDE(COUNTIF(ga_default_channel_group IS NULL), COUNT(*)) AS null_channel_rate,
  SAFE_DIVIDE(
    COUNTIF(LOWER(COALESCE(ga_default_channel_group, '')) = 'unassigned'),
    COUNT(*)
  ) AS unassigned_rate
FROM `YOUR_PROJECT_ID.YOUR_ATTRIBUTION_DATASET.ga_sessions_clean`;
