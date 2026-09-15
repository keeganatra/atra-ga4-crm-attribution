# Prompt: Adapt the Attribution Model to My CRM

Copy the prompt below into ChatGPT and attach or paste the five SQL templates plus your CRM schema or field mapping.

---

I am implementing the ATRA GA4 + CRM Attribution framework.

My goal is to adapt `03_crm_leads_clean.sql` and only the downstream SQL that genuinely needs to change for my CRM. Preserve the five-table architecture, table grains, `ga_` and `crm_` naming conventions, and existing attribution outputs unless my requirements explicitly require a change.

My configuration is:

- BigQuery project ID: [PROJECT]
- Attribution dataset: [DATASET]
- GA4 export dataset: [GA4 DATASET]
- CRM source table: [CRM TABLE]
- Business timezone: [TIMEZONE]
- Unique CRM attribution record ID: [FIELD]
- CRM field containing GA4 Client ID / visitor ID: [FIELD]
- Lead milestone field: [FIELD + DATA TYPE]
- Sale/outcome milestone definition: [DEFINITION]
- Sale/outcome field: [FIELD + DATA TYPE]
- CRM lead source field: [FIELD]
- CRM campaign ID field: [FIELD OR NONE]
- CRM campaign name field: [FIELD OR NONE]
- Other CRM dimensions I want in Data Studio: [FIELDS]

My CRM schema is:

[PASTE SCHEMA]

Instructions:

1. First identify any missing information or incompatible data types that would prevent a safe implementation.
2. Verify whether the CRM source is actually one row per chosen CRM record. If not, explain the deduplication requirement before writing final SQL.
3. Map the CRM fields into clear `crm_` output names.
4. Preserve the GA4 identity join methodology unless I explicitly change it.
5. Do not silently change milestone definitions, Direct treatment, attribution window, channel classification, or journey unit.
6. If my outcome is date-only, explicitly explain the limitation for intra-day pre-sale attribution and time-to-sale.
7. Return the COMPLETE updated SQL for every file that must change. Do not use ellipses, placeholders such as "existing code here," or partial snippets.
8. After the SQL, provide the exact QA queries I should run and explain what successful results should look like.
9. Do not modify unrelated parts of the framework merely to simplify the code.

Before proposing a fix for any error or duplicate-count issue, diagnose which table first introduces the problem.

---


## GA4 session identity
Map the CRM field containing the captured GA4 Session ID to `crm_ga_session_id` as STRING. Preserve `crm_ga_join_id` as the Client ID-based join to GA4 `user_pseudo_id`. Do not substitute Session ID for Client ID.
