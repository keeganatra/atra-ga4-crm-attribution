# ATRA GA4 + CRM Attribution Toolkit

An open implementation framework from **ATRA** for connecting GA4 behavioral data to downstream CRM outcomes in BigQuery, reconstructing customer journeys, and preparing attribution-ready reporting in Data Studio.

This project is designed to be understandable, adaptable, and auditable. It is not a black-box attribution product.

## Start here

If you are implementing this framework for a new organization, start with:

**[`prompts/new_implementation.md`](prompts/new_implementation.md)**

Then follow this sequence:

1. **Configure** the environment, CRM fields, milestones, timezone, and attribution rules.
2. **Capture identity** by storing both GA4 Client ID and GA4 Session ID with form submissions.
3. **Adapt the CRM layer** to the organization's source schema.
4. **Run SQL layers 01–05 in order.**
5. **Run all QA queries** and resolve or document failures.
6. **Certify the model as ready for reporting.**
7. **Build Data Studio reporting** from the correct reporting grains.

For browser-side identity capture, use:

- [`scripts/ga_identity_capture.js`](scripts/ga_identity_capture.js)
- [`docs/form_identity_capture.md`](docs/form_identity_capture.md)

## What this toolkit does

The framework transforms raw GA4 event exports and CRM lead/outcome data into an attribution-ready model that can answer questions such as:

- Which channels, sources, mediums, and campaigns preceded lead creation?
- Which marketing journeys preceded a downstream sale or equivalent outcome?
- How many sessions occurred before conversion?
- What were the first and last observed touches before each milestone?
- How long did users take to progress from first observed website visit to lead and downstream outcome?
- What channel paths commonly precede conversion?
- Which exact GA4 session produced the CRM conversion when Session ID capture is available?

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

| Layer | Grain | Purpose |
|---|---|---|
| **`ga_events_clean`** | One row per GA4 event | Standardizes the raw GA4 export and exposes attribution-relevant event, session, traffic, device, page, and ecommerce fields. |
| **`ga_sessions_clean`** | One row per GA4 user + session | Converts event-level activity into the default behavioral journey unit. |
| **`crm_leads_clean`** | One row per CRM attribution record | Standardizes CRM identity, milestones, downstream outcomes, and reporting dimensions. |
| **`journey_sessions`** | One row per CRM record + matched GA4 session | Connects CRM outcomes to the visitor's observed GA4 sessions and classifies sessions around conversion milestones. |
| **`lead_summary`** | Exactly one row per CRM record | Produces the reporting-safe attribution layer with first/last touch, paths, session counts, time-to-conversion, and outcomes. |

## Before you run the SQL

The SQL files are **templates, not copy-paste production queries**.

You must adapt the visible `YOUR_*` placeholders to the implementation environment before execution. At minimum, confirm:

- Google Cloud project ID
- GA4 export dataset
- attribution dataset
- CRM source table
- business timezone
- CRM record ID
- lead milestone field and data type
- downstream outcome field and data type
- GA4 Client ID CRM field
- GA4 Session ID CRM field
- CRM reporting dimensions and optional fields

### The CRM layer requires the most customization

[`sql/03_crm_leads_clean.sql`](sql/03_crm_leads_clean.sql) is intentionally CRM-agnostic and should be adapted to the source system.

Pay particular attention to:

- source data types;
- CRM deduplication/version-history logic;
- exact timestamp vs. date-only outcome fields;
- optional fields that do not exist in the source CRM; and
- the required one-row-per-`crm_record_id` grain.

Do not deploy downstream layers until `crm_leads_clean` uniqueness is validated.

## Identity model

The default identity relationship is:

**GA4 `user_pseudo_id` ↔ CRM-captured GA4 Client ID**

The Client ID is the historical browser-level identity key used to reconstruct the observed journey.

The framework also captures the **GA4 Session ID** with the form submission. Session ID is stored separately and is used to identify and validate the exact conversion session.

**Session ID supplements Client ID; it does not replace it.**

See [Form Identity Capture](docs/form_identity_capture.md) for the implementation pattern.

## Default methodology

V1 defaults to:

- GA4 `user_pseudo_id` as the website identity key.
- CRM-captured GA4 Client ID as the CRM-side historical identity key.
- CRM-captured GA4 Session ID as an exact conversion-session validation key.
- GA4 sessions as the default journey unit.
- Lead creation as the first default CRM milestone.
- Sale as the second default CRM milestone.
- All available observed history before a milestone as the default lookback.
- GA4 Default Channel Group as the default channel classification.
- Direct retained as a legitimate observed session by default.

These are defaults, not immutable rules. The architecture is intended to remain stable while CRM systems, milestones, lookback windows, dimensions, Direct treatment, and channel definitions are customized.

## Implementation sequence

### 1. Enable GA4 BigQuery export
Confirm daily `events_*` tables are available and current.

### 2. Capture GA4 identity
Add hidden form fields for:

- `ga_client_id`
- `ga_session_id`

Map both into dedicated CRM fields.

### 3. Complete the implementation configuration
Document the environment, CRM field mapping, milestones, data types, timezone, lookback, and attribution rules.

### 4. Adapt the CRM
Use [`prompts/adapt_crm.md`](prompts/adapt_crm.md) and [`sql/03_crm_leads_clean.sql`](sql/03_crm_leads_clean.sql) to create the implementation-specific CRM normalization layer.

### 5. Deploy the five SQL layers
Run in this order:

1. [`01_ga_events_clean.sql`](sql/01_ga_events_clean.sql)
2. [`02_ga_sessions_clean.sql`](sql/02_ga_sessions_clean.sql)
3. [`03_crm_leads_clean.sql`](sql/03_crm_leads_clean.sql)
4. [`04_journey_sessions.sql`](sql/04_journey_sessions.sql)
5. [`05_lead_summary.sql`](sql/05_lead_summary.sql)

### 6. Run QA
Run every query in [`qa/`](qa/) before reporting.

The implementation is not ready until record uniqueness, CRM outcomes, identity matching, milestone timing, and channel quality are understood.

### 7. Schedule the refresh
Schedule the production model to run after upstream GA4 and CRM data are available.

### 8. Build Data Studio
Use [`docs/data_studio_guide.md`](docs/data_studio_guide.md) and connect each view to the correct table grain.

## Reporting tables

### `lead_summary`
Use this as the primary source for:

- lead/outcome KPIs
- conversion rates
- first-touch attribution
- last-touch attribution
- full-path fields
- time-to-conversion
- sessions/touches before conversion
- CRM segmentation
- executive reporting

Because this table is one row per CRM record, it is the safest primary reporting layer.

### `journey_sessions`
Use this for:

- customer journey detail
- session sequence analysis
- path exploration
- detailed source / medium / campaign analysis
- pre-lead and pre-outcome behavior
- exact captured conversion-session validation

**Do not sum lead or outcome flags directly from `journey_sessions` without deduplicating to `crm_record_id`.** A single CRM record can appear once for every matched session.

## QA / Ready for Reporting gate

Before connecting the model to production reporting, validate:

- `crm_leads_clean` has the expected unique CRM grain;
- `lead_summary` has exactly one row per CRM record;
- CRM outcome counts reconcile to the source;
- Client ID capture rate is measured;
- GA4 ↔ CRM Client ID match rate is understood;
- Session ID capture and exact conversion-session match rate are understood;
- GA4 and CRM date coverage is plausible;
- no invalid post-lead sessions are classified as pre-lead;
- channel null/unassigned rates are acceptable or documented; and
- Data Studio totals reconcile to the correct reporting grain.

See the [QA SQL](qa/) and [data dictionary](docs/data_dictionary.md).

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
  attribution_rules.md
  data_dictionary.md
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

## AI-assisted implementation

The `prompts/` directory contains implementation prompts intended to help adapt the templates without changing the underlying architecture.

The prompts instruct the AI to:

- return complete changed SQL rather than partial snippets;
- preserve table grains;
- diagnose root causes before making structural changes;
- disclose date-only milestone limitations;
- preserve the GA4 Client ID / Session ID identity model; and
- rerun QA after material changes.

Always review generated SQL before running it against production data.

## What this model does — and does not — claim

This toolkit reconstructs and summarizes **observed customer journeys**.

First touch, last touch, path reporting, and session-level attribution are deterministic descriptions of observed behavior. They do **not** by themselves prove that a channel caused a conversion.

Experiments, causal impact, media mix modeling, Markov attribution, Shapley allocation, and other incrementality methods should be treated as separate or advanced extensions.

## Built by ATRA

ATRA built this framework to make the connection between paid media, website behavior, and downstream business outcomes easier to understand and audit.

The goal is straightforward: make attribution useful enough to inform decisions without hiding the methodology behind a black box.

## License

Released under the [MIT License](LICENSE).

You may use, copy, modify, and distribute this toolkit subject to the terms of the license.
