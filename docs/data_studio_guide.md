# ATRA Data Studio Attribution Template Specification

The recommended Data Studio implementation uses two primary BigQuery sources:

- `lead_summary` for CRM-record-level attribution and outcomes.
- `journey_sessions` for detailed session/journey analysis.

## Page 1: Executive Overview

**Source:** `lead_summary`

Recommended scorecards:

- Leads: `COUNT_DISTINCT(crm_record_id)`
- Sales / downstream outcomes: `SUM(crm_is_sold)`
- Lead-to-sale rate: `SUM(crm_is_sold) / COUNT_DISTINCT(crm_record_id)`
- Average sessions before lead
- Average sessions before sale
- Average days to lead
- Average days to sale
- % of CRM records with matched GA4 journey data

Recommended filters:

- Lead date
- Sale date
- CRM lead source
- CRM business dimensions

## Page 2: Lead Attribution

**Source:** `lead_summary`

Views:

- Leads by first-touch channel
- Leads by last-touch channel
- Leads by first-touch source / medium
- Leads by last-touch source / medium
- Leads by campaign
- First-touch vs. last-touch comparison
- Most common `ga_path_before_lead`

Primary fields use the `ga_*_pre_lead_*` family.

## Page 3: Sale Attribution

**Source:** `lead_summary`

Views:

- Sales by first-touch pre-sale channel
- Sales by last-touch pre-sale channel
- Lead-to-sale rate by first-touch channel
- Lead-to-sale rate by last-touch channel
- Sales by source / medium / campaign
- Most common `ga_path_before_sale`

Always calculate outcome metrics from the one-row-per-CRM-record `lead_summary` source.

## Page 4: Customer Journey

**Sources:** `journey_sessions` for session exploration; `lead_summary` for prebuilt path frequency.

Views:

- Journey session table ordered by session timestamp
- Channel path before lead
- Channel path before sale
- Sessions before conversion distribution
- Journey length buckets
- Device / channel sequence exploration

Do not sum CRM outcome flags directly from `journey_sessions`.

## Page 5: Channel & Campaign Analysis

**Sources:** primarily `lead_summary`; `journey_sessions` for detailed session behavior.

Views:

- First-touch leads/sales by channel
- Last-touch leads/sales by channel
- Source / medium breakdown
- Campaign breakdown
- Average sessions to conversion by acquisition channel
- Average time to conversion by acquisition channel

If custom channel definitions are used, create them upstream in BigQuery and expose the resulting field to Data Studio.

## Page 6: Time & Touches to Conversion

**Source:** `lead_summary`

Views:

- Distribution of `ga_sessions_before_lead`
- Distribution of `ga_sessions_before_sale`
- Distribution of `ga_days_to_lead`
- Distribution of `ga_days_to_sale`
- Average time-to-conversion by channel
- Average sessions-to-conversion by channel
- CRM-reported touch count vs. GA4 session count, when available

## Page 7: Data Quality

Recommended metrics:

- CRM records
- CRM records with GA Client ID
- CRM records matched to GA4
- Overall match rate
- Match rate when GA ID is present
- Null channel rate
- Unassigned channel rate
- Earliest/latest GA4 dates
- Earliest/latest CRM milestone dates
- Duplicate CRM record count

The production implementation may expose these as purpose-built BigQuery QA views or manually update this page during certification.

## Data Studio aggregation rules

### Safe from `lead_summary`

- Leads: `COUNT_DISTINCT(crm_record_id)`
- Sales: `SUM(crm_is_sold)`
- Conversion rate: `SUM(crm_is_sold) / COUNT_DISTINCT(crm_record_id)`
- Average sessions before lead/sale: `AVG(...)`
- Average days to lead/sale: `AVG(...)`

### Use caution from `journey_sessions`

A CRM record repeats once for every matched session. Therefore:

- use `COUNT_DISTINCT(crm_record_id)` when counting CRM records;
- do not `SUM(crm_is_sold)` as a sale count;
- use `ga_session_id` / session timestamp for session analysis;
- validate blends carefully because blending tables of different grains can multiply records.

## Methodology disclosure

Every published dashboard should document at least:

- identity key;
- lead milestone;
- downstream outcome definition;
- attribution lookback;
- journey unit (session vs. touchpoint);
- channel classification;
- Direct treatment;
- first/last-touch definition;
- date-only outcome limitations, if applicable.
