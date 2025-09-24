# Development Roadmap & Future Ideas

This document lists potential future enhancements and ideas for the ROKCT application.

### Enhance Update Checker
- **Description:** Add a configuration file (`.env` or `json`) for the update checker script instead of hardcoding values like `EMAIL` and `SITE`. Also, add an option to "snooze" major version upgrade notifications.
- **Related File:** `rokct/rokct/scripts/frappe_update_checker.sh`

### Admin Dashboard for Setup
- **Description:** Create a DocType for "Control Panel Settings" so that values like `tenant_domain` can be viewed and managed from the UI after the initial automatic setup.
