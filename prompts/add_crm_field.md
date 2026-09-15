# Prompt: Add a CRM Field

I am using the ATRA GA4 + CRM Attribution five-table model. I need to add the following CRM field(s):

[FIELD NAME, SOURCE TABLE, DATA TYPE, BUSINESS MEANING]

Update the framework so the field is available for filtering/segmentation in Data Studio.

Requirements:

1. Add the field to `crm_leads_clean` with a clear `crm_` prefix.
2. Propagate it through `journey_sessions` and `lead_summary` where necessary.
3. Preserve every existing output field and table grain.
4. Do not change attribution rules, milestone logic, identity matching, or channel classification.
5. Return COMPLETE SQL for every file that changes; no ellipses or partial snippets.
6. Identify which QA checks should be rerun after deployment.
7. Tell me whether the field should be used primarily from `lead_summary` or `journey_sessions` in Data Studio and why.
