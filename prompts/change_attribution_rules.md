# Prompt: Change Attribution Rules

I am using the ATRA GA4 + CRM Attribution model and want to change the following rule:

[DESCRIBE RULE: lookback window, Direct treatment, custom channel classification, journey unit, path dimension, first/last-touch eligibility, etc.]

Current rule:
[CURRENT]

Desired rule:
[DESIRED]

Before writing SQL:

1. Explain how this change will alter the meaning of the reported attribution metrics.
2. Identify exactly which tables and fields are affected.
3. Flag whether historical results must be rebuilt for apples-to-apples reporting.
4. Confirm that CRM record grain and identity resolution remain unchanged unless my request explicitly changes them.

Then return COMPLETE SQL for every file that must change. Do not use ellipses or partial snippets.

Afterward provide:

- QA queries for the changed rule;
- Data Studio fields/charts affected;
- the exact methodology note I should add to documentation so dashboard users understand the rule.
