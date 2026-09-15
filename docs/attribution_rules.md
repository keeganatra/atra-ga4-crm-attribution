# Attribution Rules & Customization Legend

This document defines the assumptions that control the attribution model. Treat these as configuration decisions rather than universal attribution rules.

## 1. Identity key

**Default:** GA4 `user_pseudo_id` matched to a GA4 Client ID / visitor ID stored in the CRM.

The website identifier should be captured when a user submits a lead form and stored in a dedicated CRM field. The cleaning layer standardizes both values before matching them.

**Can be customized to:** another persistent analytics identifier, authenticated user ID, or a more advanced identity-resolution strategy.

**Do not change without validating:** match rate, identifier format, identifier persistence, and whether one identifier can legitimately map to multiple CRM records.

## 2. Lead milestone

**Default:** CRM lead creation timestamp.

This establishes the point at which pre-lead sessions stop. A session occurring after this timestamp should not receive pre-lead attribution credit.

**Can be customized to:** form submission, MQL, qualified lead, consult request, application, appointment, or another organization's first meaningful conversion milestone.

## 3. Sale milestone

**Default:** a populated CRM sale date / timestamp.

**Can be customized to:** Closed Won, funded, enrolled, admitted, retained, activated, purchase completed, or another downstream business outcome.

If only a DATE is available rather than a timestamp, exact intra-day ordering cannot be known. Document the chosen handling rule.

## 4. Journey unit

**Default:** one GA4 session = one journey observation.

This is intentionally simple and auditable.

**Optional alternatives:**

- unique channel changes;
- unique source / medium changes;
- unique campaign changes;
- event-based touchpoints.

Example: `Paid Search > Paid Search > Direct > Direct` represents four sessions. Under a consecutive-channel-change definition, it represents two marketing touchpoints: `Paid Search > Direct`.

## 5. Lookback window

**Default:** all observed GA4 history prior to the applicable milestone.

**Common alternatives:** 30, 60, 90, or 180 days before conversion.

Shortening the lookback window changes both journey counts and attribution paths. Apply the same rule consistently when comparing performance.

## 6. Channel classification

**Default:** GA4 Default Channel Group.

**Can be customized to:** organization-specific classifications such as Paid Search - Brand, Paid Search - Non-Brand, Performance Max, Paid Social, Affiliate, Partner, Email, Organic Search, or other business-specific groups.

Document campaign-name or source/medium rules explicitly. Avoid manually changing historical classifications without versioning the rule.

## 7. Direct traffic

**Default:** retain Direct as an observed session/touch.

**Optional rule:** ignore or reallocate Direct when a known marketing touch exists earlier in the eligible journey.

Direct treatment should always be disclosed because changing it can materially alter first-touch, last-touch, and path reporting.

## 8. First touch

**Default:** earliest eligible observed GA4 session before the milestone.

This means "first observed touch within the available GA4 data," not necessarily the person's first-ever interaction with the organization.

## 9. Last touch

**Default:** latest eligible observed GA4 session before the milestone.

For lead attribution, use the latest session at or before the lead timestamp. For sale attribution, use the latest eligible session at or before the sale milestone according to the configured date/timestamp rule.

## 10. Full path

**Default:** chronological sequence of eligible GA4 Default Channel Groups before the milestone.

Paths can instead be generated from source / medium, campaign, or custom channel classification. The selected path dimension should be clearly labeled in Data Studio.

## 11. CRM record grain

**Default:** one row per unique CRM lead/conversion record in `lead_summary`.

If an organization uses opportunities, contacts, applications, cases, or another object as its reporting entity, the unique CRM key must be changed accordingly.

Always run the uniqueness QA after changing CRM grain.

## 12. Reporting grain

### `lead_summary`
One row per configured CRM record. Use for executive KPIs, lead/sale counts, conversion rates, first/last-touch reporting, time-to-conversion, and CRM segmentation.

### `journey_sessions`
One row per CRM record + associated GA4 session. Use for paths, sequence analysis, and session-level exploration.

Do not aggregate lead/sale totals from `journey_sessions` without deduplicating the CRM record ID.

## Change-control rule

Whenever an attribution rule changes, record:

1. the previous rule;
2. the new rule;
3. the effective date/version;
4. the tables/fields affected; and
5. whether historical results were rebuilt.

An attribution model is only useful when users can explain why a reported number was produced.
