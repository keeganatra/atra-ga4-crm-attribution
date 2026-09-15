/**
 * ATRA GA4 + CRM Attribution
 * Reusable browser-side identity capture for lead forms.
 *
 * Captures:
 * - ga_client_id: GA4 browser/client identifier. This is the primary CRM ↔ GA4 identity key.
 * - ga_session_id: GA4 session identifier for the session in which the form is submitted.
 *
 * Prerequisites:
 * - Google tag / GA4 is initialized on the page.
 * - Replace G-XXXXXXXXXX with the site's GA4 Measurement ID.
 * - Add hidden form fields named ga_client_id and ga_session_id.
 *
 * Notes:
 * - Do not replace Client ID with Session ID. Client ID supports historical journey reconstruction.
 * - Session ID is used to identify the exact conversion session.
 * - This script intentionally uses gtag('get') rather than parsing GA cookies directly.
 */

(function () {
  'use strict';

  var MEASUREMENT_ID = 'G-XXXXXXXXXX';
  var CLIENT_FIELD = 'ga_client_id';
  var SESSION_FIELD = 'ga_session_id';
  var MAX_WAIT_MS = 10000;
  var RETRY_MS = 250;

  function setFieldValue(fieldName, value) {
    if (value === undefined || value === null || value === '') return 0;

    var selector =
      'input[name="' + fieldName + '"], ' +
      'input[data-field="' + fieldName + '"], ' +
      '[name="' + fieldName + '"]';

    var fields = document.querySelectorAll(selector);

    fields.forEach(function (field) {
      if ('value' in field) {
        field.value = String(value);
      } else {
        field.setAttribute('value', String(value));
      }

      field.dispatchEvent(new Event('input', { bubbles: true }));
      field.dispatchEvent(new Event('change', { bubbles: true }));
    });

    return fields.length;
  }

  function getGAValue(field, callback) {
    try {
      if (typeof window.gtag !== 'function') return false;
      window.gtag('get', MEASUREMENT_ID, field, function (value) {
        callback(value);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  function populateIdentityFields() {
    if (typeof window.gtag !== 'function') return false;

    getGAValue('client_id', function (clientId) {
      setFieldValue(CLIENT_FIELD, clientId);
    });

    getGAValue('session_id', function (sessionId) {
      setFieldValue(SESSION_FIELD, sessionId);
    });

    return true;
  }

  function waitForGA(startedAt) {
    if (populateIdentityFields()) return;

    if (Date.now() - startedAt >= MAX_WAIT_MS) {
      return;
    }

    setTimeout(function () {
      waitForGA(startedAt);
    }, RETRY_MS);
  }

  function start() {
    waitForGA(Date.now());

    // Re-run when forms are dynamically inserted into the page.
    var observer = new MutationObserver(function (mutations) {
      var hasAddedNodes = mutations.some(function (mutation) {
        return mutation.addedNodes && mutation.addedNodes.length > 0;
      });

      if (hasAddedNodes) {
        populateIdentityFields();
      }
    });

    if (document.documentElement) {
      observer.observe(document.documentElement, {
        childList: true,
        subtree: true
      });
    }

    // Refresh periodically so long-lived pages do not retain a stale Session ID.
    window.setInterval(populateIdentityFields, 60000);

    // Refresh when the user returns to the tab/window.
    window.addEventListener('focus', populateIdentityFields);
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') {
        populateIdentityFields();
      }
    });

    // Re-populate before interaction/submission. Because gtag('get') returns via
    // callback, the periodic/focus refresh above is the primary safeguard; this
    // submit hook is a final best-effort refresh rather than the only capture point.
    document.addEventListener('pointerdown', function (event) {
      if (event.target && event.target.closest && event.target.closest('form')) {
        populateIdentityFields();
      }
    }, true);

    document.addEventListener(
      'submit',
      function () {
        populateIdentityFields();
      },
      true
    );
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
