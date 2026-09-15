# GA4 Form Identity Capture

This implementation captures both the GA4 Client ID and GA4 Session ID into hidden form fields so CRM records can be tied back to GA4.

## Required hidden fields

Add these hidden fields to every applicable lead form:

- `ga_client_id`
- `ga_session_id`

The exact CRM API field names can differ, but the values should map into dedicated CRM fields.

## Why both values matter

**GA Client ID** identifies the browser and is the primary identity key for the historical journey. In the attribution model, the cleaned CRM value should map to `crm_ga_join_id` and join to GA4 `user_pseudo_id`.

**GA Session ID** identifies the exact GA4 session in which the form was submitted. Preserve this separately as `crm_ga_session_id`. This is useful for validating the conversion session and distinguishing the exact lead-generating session from earlier sessions belonging to the same browser.

Do not replace Client ID with Session ID.

## Browser implementation

Use `scripts/ga_identity_capture.js` as the standard implementation.

Before deploying:

1. Replace `G-XXXXXXXXXX` with the site's GA4 Measurement ID.
2. Confirm the form includes hidden fields named `ga_client_id` and `ga_session_id`.
3. Deploy the script in GTM Custom HTML or site code after the Google tag is initialized.
4. Submit a test lead.
5. Confirm both hidden values are present in the form request.
6. Confirm both values are stored in CRM.
7. Confirm `ga_client_id` matches GA4 `user_pseudo_id` for test traffic in BigQuery.
8. Confirm `ga_session_id` matches the session ID associated with the lead-producing session.

## Dynamic forms

The standard script re-runs when page content changes, refreshes periodically, refreshes when the user returns to the page, and performs a final best-effort refresh around form interaction/submission. This reduces the risk of retaining a stale Session ID on long-lived pages.

If a form is inside a cross-origin iframe, the parent page cannot write directly into the iframe's fields. In that case, pass the IDs through a supported embed/query-parameter mechanism, use the form vendor's JavaScript API, or inject the capture logic within the iframe-hosted environment.

## CRM canonical fields

Recommended canonical outputs:

- `crm_ga_visitor_id_raw` — raw captured GA Client ID
- `crm_ga_join_id` — cleaned GA Client ID used for the GA4 join
- `crm_ga_session_id` — captured GA4 Session ID for the conversion session

The session ID should be stored as text to avoid coercion or precision issues across connectors.

## QA

Before certification, measure:

- CRM records with `ga_client_id`
- CRM records with `ga_session_id`
- CRM records whose Client ID matches at least one GA4 user
- CRM records whose captured Session ID matches one GA4 session for that matched user
- leads where the captured conversion session occurs after the CRM lead timestamp
- leads with multiple candidate GA4 sessions sharing the same captured session ID after identity matching

Any material mismatch should be diagnosed before changing attribution logic.


## GTM-native alternative

For implementations that prefer native GTM variables, Google documents an Analytics Client ID built-in variable and an Analytics Session ID built-in variable. Those values can be written into form fields through a Custom HTML/template implementation. Keep the same CRM field contract: Client ID is the historical identity key; Session ID identifies the exact conversion session.

## Consent behavior

If analytics storage is not available under the site's consent configuration, the GA identifiers may be unavailable. Do not fabricate fallback IDs. Measure the missing-ID rate in QA and document the consent/tracking conditions that explain it.
