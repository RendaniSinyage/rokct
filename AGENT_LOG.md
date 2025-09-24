# Agent Log

## Project: Roadmap and Codebase Onboarding (Sept 2025)

**Status: Completed**

This project focused on setting up the development environment for the Juvo conversion project and creating a new `Roadmap` doctype to track the progress.

### Key Changes:
-   **New `Roadmap` DocType:** A new `Roadmap` DocType was created in the `paas` module to track the conversion of the Juvo applications. This includes a child table for features and a status field.
-   **Initial Roadmap Data:** The `install.py` script was updated to create the initial roadmap data (backend, frontend, etc.) only on the control panel site.
-   **Documentation:** The `paas/README.md` file was updated to explain the purpose of the `Roadmap` DocType and to provide guidance for developers working on the Juvo conversion.

---

### Agent Instructions

**IMPORTANT:** This repository now contains an `API_GUIDE.md` file that documents the API workflow for frontend developers. Any changes made to the user signup, login, or provisioning flow **must** be reflected in this guide. Please ensure it is kept up-to-date.

---

This log tracks the major features implemented in the `rokct` custom Frappe app.

## Project: Multi-Feature Implementation & Bugfixes (Sept 2025)

**Status: Completed**

This project involved the implementation of several large-scale features and the resolution of critical bugs related to installation and configuration.

### Key Changes:
-   **Subscription Plans & PaaS Module:** A full suite of subscription plans (Free, Pro, Team, Ultra, PaaS) were created as fixtures. A new `paas` module was created to house PaaS-specific features, including its own versioning.
-   **Weather Feature:** A robust weather feature was implemented with a proxy architecture. The control panel securely fetches data from an external API (with caching and retry logic), and tenant sites make authenticated calls to the control panel. A `Weather Settings` doctype was created to manage the API key.
-   **Competitor Doctype Enhancements:** The `Competitor` doctype was modified to change the `headquarters_location` to a `Text` field and to add a child table for multiple office geolocations.
-   **App & Module Versioning:** Implemented versioning for both the `rokct` app and the `paas` module, with versions displayed in the "About" dialog.
-   **Bug Fixes:**
    -   Resolved a critical `ModuleNotFoundError` that was preventing the app from being installed. This was caused by an incorrect module structure and a faulty import path.
    -   Fixed a `401 Unauthorized` error when calling the weather API by using the correct `get_password()` method to retrieve the API key from the `Password` field type.

---

## Project: Code Quality, Automation & New Features

**Status: Completed**

This project focused on improving the overall quality, security, and maintainability of the application, as well as adding new features.

### Key Changes:
-   **Automated Setup:** A fully automatic, non-interactive setup script was created in `rokct/install.py`. It runs on `after_install` and configures the control panel site (`platform.rokct.ai`) with all necessary values, requiring no manual file editing.
-   **API Hardening:** All custom API endpoints in both the `control_panel` and `tenant` modules were hardened with strict input validation. A critical security flaw in the `initial_setup` API was also fixed by replacing `subprocess` calls with the safe `frappe.conf.set_value` method.
-   **Configuration Centralization:** All hardcoded URLs, API endpoints, and protocol schemes were removed from the codebase and replaced with dynamic calls to `frappe.conf`.
-   **New 'Competitor' DocType:** A comprehensive `Competitor` DocType was created, along with four child doctypes (`Competitor Product`, `Competitor Opportunity`, `Competitor Customer Win`, `Competitor Team Intel`) to provide a 360-degree view of competitors.
-   **New Update Checker Script:** A new utility script, `frappe_update_checker.sh`, was added to `rokct/scripts/`. It automates checking for Frappe app updates, takes backups, and sends email notifications. The script's logic was refined based on user feedback to be more robust.

---

## Project: Architectural Refactor to Multi-Site SaaS

**Status: Completed**

This project involved a fundamental refactoring of the application from a multi-company, single-site model to a more robust and scalable multi-site (one site per company) architecture.

### Key Changes:
-   **New Architecture:** The app is now a "smart app" with distinct `control_panel` and `tenant` logic paths.
-   **New Provisioning Flow:** The old signup API was replaced with a new `provision_new_tenant` API on the control panel for creating new sites.
-   **Centralized Subscriptions:** Subscription and billing logic now runs only on the control panel. Tenant sites fetch their status via a secure API.
-   **Secure Inter-Site Communication:** A shared-secret authentication model was implemented for all APIs between the control panel and tenants.
-   **Code Cleanup:** All obsolete code, hooks, and permissions related to the old multi-company data isolation model have been removed.

---

## Project: Full Data Isolation for SaaS

**Status: Obsolete**

**Note:** This project has been superseded by the "Architectural Refactor to Multi-Site SaaS" project. The application no longer uses company-field-based data isolation; it now uses database-level isolation provided by the multi-site architecture.

---

## Project: Subscription & Trial Management System

**Status: Completed & Refactored**

This project introduced a full-featured subscription management system. The core doctypes (`Company Subscription`, `Subscription Plan`) are still in use, but the logic has been refactored to run on the control plane in the new multi-site architecture.

-   **Data Model:** `Company Subscription`, `Subscription Plan`, `Subscription Settings`, and `Industry` doctypes. The `Company Subscription` doctype has been updated to link to a `Customer` instead of a `Company`.
-   **Signup API:** The original `signup_with_company` API has been deprecated and replaced by the new provisioning flow.
-   **Module Access Control:** The `on_login` hook still syncs user roles, but it now gets the subscription status via a secure API call to the control plane.
-   **Daily & Monthly Jobs:** These jobs now run only on the control plane.

## Project: Automation and Maintenance

**Status: Partially Obsolete**

-   **Weekly Maintenance Job:** The part of this job that detected un-isolated doctypes is now obsolete. The module access setup part is still relevant for the control plane.

## Project: Tender Aggregation System

**Status: Active**

This project is ongoing and is not significantly impacted by the architectural changes.

---

## Testing

This app uses a `pytest` based testing framework. The environment is "benchless".

To run the tests:

1.  **Navigate to the app directory:**
    ```bash
    # Assuming your bench directory is the root of the project
    cd /app
    ```

2.  **Install development dependencies:**
    ```bash
    pip install -r dev-requirements.txt
    ```

3.  **Run the test suite:**
    ```bash
    pytest
    ```
**Note:** The test environment is currently experiencing issues where tests fail during collection because the `frappe` module cannot be found. The `pytest-frappe` plugin, which should handle this, does not seem to be configured correctly. This requires further investigation.
