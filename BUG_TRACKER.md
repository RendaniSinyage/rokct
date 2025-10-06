# Bug Tracker

This document tracks the list of identified bugs in the `rokct` repository. Each bug will be marked as complete after it has been fixed and successfully verified.

---

### Bug 1: Provisioning Failures due to Missing Custom Fields
-   **Status:** Completed
-   **Location:** `rokct/install.py`, `rokct/control_panel/provisioning.py`
-   **Issue:** The root cause of all provisioning failures was that custom fields (`trial_period_days`, `billing_cycle`) were not being created reliably. This has been fixed by programmatically creating them in the `install.py` script.
-   **Impact:** This caused fatal `AttributeError` crashes when provisioning any paid plan, preventing customers from signing up.

---

### Bug 2: Critical Typo in Subscription Billing Logic
-   **Status:** Completed
-   **Location:** `rokct/rokct/control_panel/tasks.py`
-   **Issue:** Billing functions use incorrect values (`'Month'`, `'Year'`) when checking the billing cycle.
-   **Impact:** This would have broken the automated billing system for all paid plans. This was fixed in the same pass as Bug 1.

---

### Bug 3: Invalid "Dropped" Status
-   **Status:** Completed
-   **Location:** `rokct/rokct/doctype/company_subscription/company_subscription.json`
-   **Issue:** The `drop_tenant_site` function attempts to set a "Dropped" status that was not a valid option in the doctype, causing an error.
-   **Impact:** This prevented the subscription status from being correctly updated after a site was deleted.

---

### Bug 4: Missing Transaction Record on Add-on Charge
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/control_panel/billing.py`
-   **Issue:** The `charge_customer_for_addon` function charges customers but creates no local record of the transaction.
-   **Impact:** This leads to no audit trail for revenue, inaccurate accounting, and a risk of double-charging.

---

### Bug 5: Token Usage Not Resetting Monthly
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/tenant/api.py`
-   **Issue:** The `record_token_usage` function tracks AI token usage but never resets the counter monthly.
-   **Impact:** After the first month, users will be permanently locked out from using AI features once they hit their limit.

---

### Bug 6: Temporary Support Users Are Not Automatically Disabled
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/tenant/api.py`
-   **Issue:** The system creates temporary support users with an expiration date but has no automated process to disable them.
-   **Impact:** This is a security flaw, as privileged accounts remain active indefinitely unless manually cleaned up.

---

### Bug 7: Insecure "Fail Open" Logic in Feature Check
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/utils/subscription_checker.py`
-   **Issue:** The function that checks if a user's plan includes a feature grants access if it cannot contact the central server.
-   **Impact:** This is a security risk, as an attacker could force an error to gain free access to paid features.

---

### Bug 8: Hardcoded Default Customer Group
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/utils/customer.py`
-   **Issue:** The `get_or_create_customer` function hardcodes the Customer Group, which can be renamed or deleted by an admin.
-   **Impact:** If the default group is ever changed, this function will consistently fail.

---

### Bug 9: Roadmap Settings UI Bug
-   **Status:** To Be Discussed
-   **Location:** `rokct/roadmap/doctype/roadmap_settings/`
-   **Issue:** The `github_action_secret` field is a `Password` type, preventing the browser from rendering a "Copy to Clipboard" button.
-   **Impact:** The user cannot copy the generated secret from the UI.

---

### Bug 10: Incorrect API Endpoint in Subscription Form
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/doctype/company_subscription/company_subscription.js`
-   **Issue:** The "Resend Welcome Email" button calls a non-existent API endpoint.
-   **Impact:** The button is completely broken.

---

### Bug 11: Stale Subscription Details Due to Caching
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/tenant/api.py`
-   **Issue:** Subscription details are cached on the tenant site for up to 24 hours with no invalidation mechanism.
-   **Impact:** When a user upgrades their plan, they may not see the changes for up to 24 hours.

---

### Bug 12: Missing Email Template File
-   **Status:** To Be Discussed
-   **Location:** `rokct/rokct/control_panel/tasks.py`
-   **Issue:** The `frappe.sendmail` function fails because the specified email template, "New User Welcome," does not exist.
-   **Impact:** This prevents the welcome email from being sent to new users after provisioning.