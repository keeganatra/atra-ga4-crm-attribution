# Prompt: Create a New Implementation

Use this prompt after completing the implementation configuration and CRM field mapping.

```text
You are adapting ATRA's five-layer GA4 + CRM attribution model to a new implementation.

I will provide:
1. the five canonical SQL templates;
2. my completed implementation configuration;
3. the source CRM schema; and
4. any custom attribution rules.

Your job is to produce complete BigQuery GoogleSQL for all five tables:
- ga_events_clean
- ga_sessions_clean
- crm_leads_clean
- journey_sessions
- lead_summary

Rules:
- Preserve the five-layer architecture unless I explicitly request an architectural change.
- Do not invent source fields. If a required mapping is missing, identify it before generating SQL.
- Use the configured timezone for CRM/GA4 milestone comparisons.
- Preserve the intended table grain of every layer.
- lead_summary must contain exactly one row per configured unique CRM record ID.
- Treat GA4 sessions as the default journey unit unless my configuration says otherwise.
- Use the configured lead and downstream-sale milestones.
- Use all available pre-conversion history unless a lookback window is configured.
- Retain Direct unless my configuration specifies another rule.
- Keep GA4-derived output fields prefixed ga_ and generalized CRM-derived fields prefixed crm_.
- Prefer readable, auditable SQL over advanced optimization.
- Use BigQuery-compatible GoogleSQL only.
- Never use placeholders such as "..." inside executable SQL.
- Return complete executable queries.
- After the SQL, provide the QA queries required to verify uniqueness, identity matching, outcome reconciliation, dates, and channel quality.

Before changing the canonical model, explain any source-schema limitation that requires the change.

Implementation configuration:
[PASTE CONFIGURATION HERE]

CRM schema:
[PASTE CRM SCHEMA HERE]

Canonical SQL templates:
[PASTE OR ATTACH THE FIVE SQL FILES HERE]

Custom rules:
[PASTE CUSTOM RULES HERE]
```


## Identity capture requirement
Confirm that website forms capture both `ga_client_id` and `ga_session_id`. Map Client ID to the CRM visitor/join field and Session ID to a dedicated CRM field that becomes `crm_ga_session_id`. Do not use Session ID as the historical journey join.
