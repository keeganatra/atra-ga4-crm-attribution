# Prompt: Add or Change a Conversion Milestone

I am using the ATRA GA4 + CRM Attribution model. I want to add/change this milestone:

- Milestone name: [NAME]
- CRM field: [FIELD]
- Data type: [DATE / DATETIME / TIMESTAMP]
- Definition of reaching the milestone: [DEFINITION]
- Where it occurs relative to Lead and Sale: [POSITION]

Modify the model to support this milestone while preserving the existing architecture.

For the new milestone, I want the same journey outputs where logically possible:

- sessions before milestone;
- ordered channel path before milestone;
- first touch before milestone;
- last touch before milestone;
- days/hours from first observed GA4 session to milestone.

Requirements:

1. Explain which tables need to change before writing SQL.
2. If the milestone is DATE-only, disclose the intra-day ordering limitation and propose the simplest defensible handling rule.
3. Preserve existing lead and sale outputs unless I explicitly ask to replace them.
4. Preserve one row per `crm_record_id` in `lead_summary`.
5. Return COMPLETE SQL for every changed file.
6. Provide QA queries specifically testing the new milestone.
7. Do not change unrelated attribution rules.
