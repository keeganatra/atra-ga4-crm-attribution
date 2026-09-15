# ATRA GA4 + CRM Attribution

A reusable implementation framework for connecting GA4 behavioral data to downstream CRM outcomes in BigQuery and visualizing the resulting attribution data in Data Studio.

> **Status:** Private V1 development. The framework is designed for eventual external publication.

## What this toolkit does

The framework transforms raw GA4 event exports and CRM lead/outcome data into an attribution-ready model that can answer questions such as:

- Which channels, sources, mediums, and campaigns preceded lead creation?
- Which marketing journeys preceded a downstream sale or equivalent outcome?
- How many sessions occurred before conversion?
- What were the first and last known marketing touches before each milestone?
- How long did users take to progress from first observed website visit to lead and sale?
- What channel paths commonly precede conversion?

## Core architecture

```text
GA4 BigQuery Export
       |
       v
01 ga_events_clean
       |
       v
02 ga_sessions_clean
       |
       +-------------------+
                           v
CRM Source ---> 03 crm_leads_clean
                           |
                           v
                  04 journey_sessions
                           |
                           v
                    05 lead_summary
                           |
                           v
                      Data Studio
```

### Five model layers

1. **ga_events_clean** — Standardizes raw GA4 events and extracts commonly needed nested fields.
2. **ga_sessions_clean** — Converts event-level activity into one record per observed GA4 session.
3. **crm_leads_clean** — Standardizes the organization's CRM records, milestones, identity key, and reporting dimensions.
4. **journey_sessions** — Connects CRM outcomes to the GA4 sessions associated with the same visitor and identifies sessions occurring before each milestone.
5. **lead_summary** — Produces an analysis-friendly lead-level table containing journey counts, paths, first/last touches, time-to-conversion, and downstream outcomes.

## Default methodology

V1 uses:

- GA4 `user_pseudo_id` as the website identity key.
- A corresponding GA4 Client ID / visitor ID stored in the CRM as the CRM-side identity key.
- A captured GA4 Session ID stored separately to identify the exact conversion session.
- GA4 sessions as the default journey unit.
- Lead creation as the first default CRM milestone.
- Sale as the second default CRM milestone.
- All available history before a milestone as the default lookback window.
- GA4 Default Channel Group as the default channel classification.
- Direct traffic retained by default, with optional alternative treatment documented separately.

These are defaults rather than requirements. The implementation is intentionally designed so organizations can substitute CRM systems, milestones, dimensions, attribution windows, and channel rules without redesigning the complete architecture.

## Repository structure

```text
sql/
  01_ga_events_clean.sql
  02_ga_sessions_clean.sql
  03_crm_leads_clean.sql
  04_journey_sessions.sql
  05_lead_summary.sql

qa/
  01_record_uniqueness.sql
  02_identity_match_rate.sql
  03_crm_outcomes.sql
  04_date_validation.sql
  05_channel_validation.sql

docs/
  data_dictionary.md
  attribution_rules.md
  data_studio_guide.md
  form_identity_capture.md

scripts/
  ga_identity_capture.js

prompts/
  new_implementation.md
  adapt_crm.md
  add_crm_field.md
  add_milestone.md
  change_attribution_rules.md
  troubleshoot.md
```

## Implementation sequence

1. Enable the GA4 daily BigQuery export.
2. Capture both GA4 Client ID and GA4 Session ID on website conversions and map them into dedicated CRM fields.
3. Complete the implementation configuration and CRM field mapping.
4. Deploy the five SQL layers in order.
5. Run the QA suite and resolve failures before reporting.
6. Schedule the production query to refresh after upstream GA4 and CRM data are available.
7. Connect the approved reporting tables to the ATRA Data Studio template.
8. Customize milestones, attribution windows, Direct treatment, and channel rules as needed.

## Reporting tables

Use **lead_summary** for lead-level KPIs, outcomes, first/last-touch reporting, time-to-conversion, CRM segmentation, and executive reporting.

Use **journey_sessions** for session-level journey analysis, pathing, sequence analysis, and detailed channel/source/medium/campaign exploration.

Do not sum lead or sale flags directly from `journey_sessions` without deduplicating to the CRM record grain. A single CRM record can have many journey-session rows.

## QA requirement

An implementation should not be considered ready for Data Studio until the QA suite confirms, at minimum:

- expected CRM record uniqueness;
- CRM outcome counts reconcile to the source system;
- GA4-to-CRM identity match rate is understood;
- journey milestone timing is valid;
- channel/source fields have acceptable null and unassigned rates; and
- reporting-table grains are understood and validated.

## ATRA methodology

This framework is maintained by ATRA Digital. It is intended to make GA4 + CRM attribution understandable, customizable, and auditable rather than treating attribution as a black box.
