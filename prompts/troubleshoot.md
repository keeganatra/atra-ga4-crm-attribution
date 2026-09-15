# Prompt: Troubleshoot the Attribution Pipeline

I am using the ATRA GA4 + CRM Attribution five-table model and have this problem:

[DESCRIBE ERROR, WRONG COUNT, DUPLICATE, NULL RATE, MATCH ISSUE, OR REPORTING DISCREPANCY]

Observed result:
[PASTE RESULT]

Expected result:
[EXPECTED]

Relevant SQL/schema/error message:
[PASTE]

Do not immediately rewrite the final table.

Troubleshoot in pipeline order:

1. `ga_events_clean`
2. `ga_sessions_clean`
3. `crm_leads_clean`
4. `journey_sessions`
5. `lead_summary`

Identify the FIRST layer where the result becomes incorrect. Distinguish between:

- source-data issue;
- identity-match issue;
- duplicate CRM grain;
- timestamp/timezone issue;
- milestone-definition issue;
- session attribution issue;
- SQL implementation error;
- Data Studio aggregation/grain error.

Only after diagnosing the root cause should you propose a fix.

If SQL must change:

- return the COMPLETE corrected query for every affected file;
- preserve unrelated fields and logic;
- do not use ellipses or placeholders;
- provide validation queries proving the fix worked;
- explain whether historical data needs to be rebuilt.
