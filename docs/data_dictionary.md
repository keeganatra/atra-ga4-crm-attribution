# Data Dictionary & Data Studio Usage

This document explains the five-table ATRA GA4 + CRM attribution model, the grain of each table, and which tables should be used for specific types of Data Studio reporting.

## The most important reporting rule

**Use `lead_summary` for CRM-record-level metrics. Use `journey_sessions` for journey/session-level analysis.**

A CRM record can have multiple GA4 sessions. Therefore, `journey_sessions` contains multiple rows for many CRM records. Summing lead or sale metrics from that table without deduplication will overcount outcomes.

## 1. `ga_events_clean`

**Grain:** One row per GA4 event.

**Purpose:** Cleans the raw GA4 BigQuery export and exposes nested GA4 fields in a more accessible structure.

**Use for:** Technical validation, event-level analysis, custom event parameters, page behavior, ecommerce detail, and building additional session features.

**Data Studio:** Generally do not use this as the primary attribution reporting source. It is too granular for most dashboard KPIs and is easier to misuse.

Key field families:

- `ga_event_*` — event date, timestamp, name and local datetime.
- `ga_user_*` — GA4 visitor/user identifiers and first-touch timestamp.
- `ga_session_id`, `ga_session_number` — session identifiers extracted from event parameters.
- `ga_page_*` — page URL and referrer.
- `ga_first_user_*` — first-user acquisition dimensions.
- `ga_manual_*` — collected/manual traffic dimensions.
- `ga_stslc_*` — session traffic source last-click fields.
- `ga_default_channel_group` — GA4 Default Channel Group.
- `ga_device_*`, `ga_geo_*` — device and geography.

## 2. `ga_sessions_clean`

**Grain:** One row per `ga_user_pseudo_id` + `ga_session_id`.

**Purpose:** Converts raw GA4 events into website sessions, which are the default journey unit in V1.

**Use for:** Session counts, traffic mix, channel/source/medium/campaign QA, and GA4-only session analysis.

**Data Studio:** Can be used for GA4-only traffic analysis, but CRM attribution reporting should normally use `lead_summary` or `journey_sessions`.

Important fields:

| Field | Definition | Reporting use |
|---|---|---|
| `ga_user_pseudo_id` | GA4 browser/client identifier | Identity matching / QA |
| `ga_session_id` | GA4 session identifier | Session counting |
| `ga_session_start_timestamp_utc` | First event timestamp in session | Journey ordering |
| `ga_session_start_datetime_local` | Session start in configured business timezone | Human-readable reporting |
| `ga_source` | Resolved session source | Attribution dimension |
| `ga_medium` | Resolved session medium | Attribution dimension |
| `ga_campaign` | Resolved session campaign | Campaign analysis |
| `ga_default_channel_group` | GA4 Default Channel Group | Primary default channel dimension |
| `ga_event_count` | Events observed in the session | Engagement context |
| `ga_event_names` | Distinct events observed | Session behavior context |

## 3. `crm_leads_clean`

**Grain:** Intended to be exactly one row per `crm_record_id`.

**Purpose:** Standardizes the CRM into a stable interface for the attribution model. This is the primary customization layer when adapting the framework to a new CRM.

**Use for:** CRM outcome reconciliation, CRM dimensions, identity capture validation, and source-system QA.

**Data Studio:** Useful for CRM-only validation, but the final attribution dashboard should normally use `lead_summary`.

Important fields:

| Field | Definition | Reporting use |
|---|---|---|
| `crm_record_id` | Unique lead / attribution record | Primary CRM grain |
| `crm_lead_created_timestamp` | Default lead milestone | Lead timing |
| `crm_sale_date` | Default downstream sale milestone | Sale timing |
| `crm_is_sold` | 1 when sale milestone exists | Sale count / conversion rate |
| `crm_ga_join_id` | Cleaned GA visitor identifier | GA4-to-CRM join |
| `crm_ga_session_id` | Captured GA4 Session ID for the lead-generating session | Exact conversion-session validation |
| `crm_lead_source` | CRM lead source | CRM segmentation |
| `crm_campaign_id` | CRM campaign identifier | CRM segmentation |
| `crm_campaign_name` | CRM campaign name | CRM segmentation |
| `crm_reported_touch_count` | CRM's own touch count, if available | Compare CRM vs GA4 behavior |
| `crm_*click_id` | Advertising/platform identifiers | QA / advanced analysis |
| `crm_custom_*` | Implementation-specific CRM dimensions | Filtering / segmentation |

## 4. `journey_sessions`

**Grain:** One row per `crm_record_id` + matched GA4 session.

**Purpose:** Creates the actual behavioral journey by attaching all known GA4 sessions for a visitor to the corresponding CRM record.

**Use for:** Pathing, sequence analysis, session-level source/medium/campaign exploration, pre-lead/pre-sale behavior, and advanced attribution analysis.

**Data Studio:** Use this table for the Customer Journey and detailed Channel/Campaign pages. Do not sum CRM outcomes without deduplicating to `crm_record_id`.

Important fields:

- All selected `crm_*` dimensions from `crm_leads_clean`.
- All selected session dimensions from `ga_sessions_clean`.
- `ga_is_captured_conversion_session` — 1 when the matched GA4 session ID equals the Session ID captured with the CRM record.
- `ga_is_pre_lead_session` — session started on/before the lead milestone.
- `ga_is_pre_sale_session` — session occurred on/before the downstream sale milestone under the configured sale-date rule.

## 5. `lead_summary`

**Grain:** Exactly one row per `crm_record_id`.

**Purpose:** Converts the detailed journey into the primary reporting table for attribution and business outcomes.

**Data Studio:** This should be the default source for executive and CRM-record-level reporting.

### Outcome fields

| Field | Definition | Data Studio use |
|---|---|---|
| `crm_record_id` | Unique CRM record | `COUNT_DISTINCT` or record-level dimension |
| `crm_is_sold` | Downstream outcome flag | `SUM(crm_is_sold)` for sales |
| `crm_lead_created_timestamp` | Lead milestone | Date dimensions / cohorting |
| `crm_sale_date` | Sale milestone | Sale date reporting |

### Journey volume fields

| Field | Definition | Data Studio use |
|---|---|---|
| `ga_total_sessions` | All matched sessions for the visitor | Average sessions / distribution |
| `ga_captured_conversion_session_matches` | Count of matched GA4 sessions whose session ID equals the CRM-captured conversion Session ID | Identity/session QA; normally 1 when capture is working |
| `ga_sessions_before_lead` | Sessions before lead milestone | Avg. sessions to lead |
| `ga_sessions_before_sale` | Sessions before sale milestone | Avg. sessions to sale |

### Time-to-conversion fields

| Field | Definition | Data Studio use |
|---|---|---|
| `ga_days_to_lead` | Days from first observed session to lead | Avg./median time to lead |
| `ga_hours_to_lead` | Hours from first observed session to lead | Short-cycle businesses |
| `ga_days_to_sale` | Approx. days from first session to sale when sale is date-only | Avg./distribution |
| `ga_hours_to_sale` | Approx. hours to sale when sale is date-only | Use cautiously unless exact sale timestamp exists |

### Path fields

| Field | Definition | Data Studio use |
|---|---|---|
| `ga_path_before_lead` | Ordered channel sequence before lead | Path table / path frequency |
| `ga_path_before_sale` | Ordered channel sequence before sale | Sale journey analysis |

### First/last-touch fields

The table contains source, medium, campaign, channel group, and timestamp variants for:

- `ga_first_touch_pre_lead_*`
- `ga_last_touch_pre_lead_*`
- `ga_first_touch_pre_sale_*`
- `ga_last_touch_pre_sale_*`

Use these fields to create first-touch and last-touch attribution views without recalculating session order in Data Studio.

## Recommended Data Studio source mapping

| Dashboard area | Primary table |
|---|---|
| Executive Overview | `lead_summary` |
| Lead Attribution | `lead_summary` |
| Sale Attribution | `lead_summary` |
| Time & Touches to Conversion | `lead_summary` |
| CRM segmentation | `lead_summary` |
| Customer Journey | `journey_sessions` + summary path fields |
| Detailed Channel/Campaign journey analysis | `journey_sessions` |
| Data Quality / Match Rate | QA outputs or purpose-built QA views |

## Prefix convention

- `ga_` = derived from GA4 or calculated from GA4 behavior.
- `crm_` = sourced from or defined by the CRM.

Keeping these prefixes is strongly recommended because it makes field lineage visible to analysts and dashboard users.
