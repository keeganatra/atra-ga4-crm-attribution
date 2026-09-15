# Attribution Rules & Customization Legend

The ATRA model separates **architecture** from **business rules**. The five-table architecture should remain stable while the rules below are customized to the organization.

## 1. Identity key

**Default:** GA4 `user_pseudo_id` matched to a GA4 Client ID / visitor ID stored in the CRM.

### Hidden form field pattern

1. Create a hidden field on lead forms such as `ga_client_id`.
2. Populate the hidden field with the browser's GA4 Client ID before submission.
3. Include that value in the form payload.
4. Map the form field to a dedicated CRM field.
5. Preserve the value as text in the CRM and downstream warehouse.
6. Add a second hidden field such as `ga_session_id` and populate it with the active GA4 Session ID at submission time.
7. Map Client ID and Session ID into separate CRM fields and preserve both as text.
8. Validate that sample Client IDs match GA4 `user_pseudo_id` values in BigQuery.
9. Validate that the captured Session ID matches the exact GA4 session associated with the form submission.

**Important:** Client ID remains the historical journey join. Session ID is a secondary validation key that identifies the exact conversion session; it does not replace Client ID.

For the standard implementation, use `scripts/ga_identity_capture.js` and `docs/form_identity_capture.md`.

The exact implementation varies by form platform, GTM setup, consent configuration, and CRM.

**Can be customized to:** another persistent analytics identifier, authenticated user ID, or a more advanced identity-resolution strategy.

**Do not change without validating:** match rate, identifier format, identifier persistence, and whether one identifier can legitimately map to multiple CRM records.

## 2. Lead milestone

**Default:** CRM lead creation timestamp.

This establishes the point at which pre-lead sessions stop. A session occurring after this timestamp should not receive pre-lead attribution credit.

**Can be customized to:** form submission, MQL, qualified lead, consult request, application, appointment, or another organization's first meaningful conversion milestone.

## 3. Sale milestone

**Default:** a populated CRM sale date / timestamp.

**Can be customized to:** Closed Won, funded, enrolled, admitted, retained, activated, purchase completed, or another downstream business outcome.

Prefer an exact timestamp over a date when available. If only a DATE is available, exact intra-day ordering cannot be known and the chosen handling rule must be documented.

## 4. Journey unit

**Default:** one GA4 session = one journey observation.

This is intentionally simple and auditable.

**Optional alternatives:** unique channel changes, source/medium changes, campaign changes, or event-based touchpoints.

Example: `Paid Search > Paid Search > Direct > Direct > Organic Search` represents five sessions. Under a consecutive-channel-change definition it represents three marketing touchpoints: `Paid Search > Direct > Organic Search`.

Do not use the words **session** and **touchpoint** interchangeably in reporting.

## 5. Lookback window

**Default:** all observed GA4 history prior to the applicable milestone.

**Common alternatives:** 30, 60, 90, or 180 days before conversion.

Shortening the lookback window changes journey counts and attribution paths. A lookback rule should be applied relative to the milestone, not simply as a Data Studio date filter.

## 6. Channel classification

**Default:** GA4 Default Channel Group.

**Can be customized to:** organization-specific classifications such as Paid Search - Brand, Paid Search - Non-Brand, Performance Max, Paid Social Prospecting, Paid Social Retargeting, Affiliate, Partner, Email, Organic Search, or other business-specific groups.

Document campaign-name or source/medium rules explicitly. Prefer implementing custom channel logic upstream in SQL instead of recreating it independently in multiple Data Studio charts.

## 7. Direct traffic

**Default:** retain Direct as an observed session/touch.

**Optional rules:**

1. Keep Direct exactly as observed.
2. Exclude Direct from first/last marketing-touch reporting.
3. Reassign Direct to the most recent known non-Direct marketing touch.

Direct treatment should always be disclosed because changing it can materially alter first-touch, last-touch, and path reporting.

## 8. First touch

**Default:** earliest eligible observed GA4 session before the milestone.

This means "first observed touch within the available GA4 data," not necessarily the person's first-ever interaction with the organization.

## 9. Last touch

**Default:** latest eligible observed GA4 session before the milestone.

For lead attribution, use the latest session at or before the lead timestamp. For sale attribution, use the latest eligible session at or before the sale milestone according to the configured date/timestamp rule.

## 10. Full path

**Default:** chronological sequence of eligible GA4 Default Channel Groups before the milestone.

Paths can instead use source / medium, campaign, custom channel, compressed marketing touchpoints, or a combination such as channel > campaign. The selected path dimension should be clearly labeled in Data Studio.

## 11. CRM record grain

**Default:** one row per unique CRM lead/conversion record in `lead_summary`.

If an organization uses opportunities, contacts, applications, cases, accounts, or another object as its reporting entity, the unique CRM key must be changed accordingly.

Always run the uniqueness QA after changing CRM grain.

## 12. Reporting grain

### `lead_summary`
One row per configured CRM record. Use for executive KPIs, lead/sale counts, conversion rates, first/last-touch reporting, time-to-conversion, and CRM segmentation.

### `journey_sessions`
One row per CRM record + associated GA4 session. Use for paths, sequence analysis, and session-level exploration.

Do not aggregate lead/sale totals from `journey_sessions` without deduplicating the CRM record ID.

## 13. Journey attribution vs. incrementality

First touch, last touch, and path reporting are deterministic views of observed customer journeys. They do not prove that a channel caused the conversion.

Markov attribution, Shapley allocation, experiments, causal impact, and media mix modeling should be treated as advanced extensions rather than silently substituted for the core journey model.

## Change-control rule

Whenever an attribution rule changes, record:

1. the previous rule;
2. the new rule;
3. the effective date/version;
4. the tables/fields affected; and
5. whether historical results were rebuilt.

An attribution model is only useful when users can explain why a reported number was produced.
