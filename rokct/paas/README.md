# PaaS Module Development Guide

This document provides architectural guidelines and instructions for developers working on the `PaaS` module of the ROKCT application.

## Core Architectural Principle

The primary architectural approach for this module is to **extend existing Frappe functionality** wherever possible, rather than creating new, separate modules for core concepts.

For example, when adding features related to user management, we should extend the standard Frappe `User` doctype with custom fields. A separate, custom "User Management" module should only be created if the features are fundamentally different from the core `User` concept and cannot be achieved through extension. This principle applies to other core features as well.

## Development Priority & API Conversion

The immediate priority is to **convert the existing Laravel backend** into Frappe/ROKCT. The goal is to replicate the Laravel API contract perfectly within the Frappe backend.

This will allow the various frontend applications (Flutter, React) to be switched over to the new Frappe backend simply by changing their base URL. This minimizes the need for changes in the frontend applications.

## Codebase for Analysis

To facilitate the conversion, the source code for the original applications will be placed in the `paas/juvo/` directory:

*   `paas/juvo/backend/`: Contains the source code for the original Laravel backend. **This should be your primary reference for the API conversion.**
*   `paas/juvo/frontend/`: The ReactJS admin frontend.
*   `paas/juvo/customer/`: The Flutter customer/user mobile app.
*   `paas/juvo/manager/`: The Flutter manager mobile app.
*   `paas/juvo/pos/`: The Flutter Point-of-Sale (POS) mobile app.
*   `paas/juvo/web/`: The customer-facing web application.
*   `paas/juvo/driver/`: The Flutter driver mobile app.

**Important:** Before starting work, developers **must** first analyze the relevant codebase in `paas/juvo/`. If you need to understand the behavior of the core Frappe framework or other installed apps, you can refer to the code in the `/analyze` directory at the root of the repository. This will provide direct access to the code and help avoid guesswork.

## Completed & Excluded Features

*   **Completed:** The **Weather Feature** has been fully implemented and is functional. It should not be worked on again.
*   **Excluded:** The features related to **"erpgo"** and **"sling" / "slingbolt"** are considered unfinished and are out of scope for the current conversion effort. Do not work on these features.

## Roadmap for Juvo Conversion

A `Roadmap` DocType has been created to track the progress of the Juvo application conversion. This roadmap is for internal use on the control panel only and is not a feature intended for tenants. The roadmap data is used to manage the development and conversion process.

*   **Excluded:** The **Roadmap Feature** is not a user-facing feature for tenants.

## Project Tracking & Documentation

To maintain clarity on the project's progress, we use several key documents. It is crucial that these files are kept synchronized to provide a consistent view of the development status.

*   **`TODO.md`**: This file contains a high-level list of active and pending tasks. It serves as a quick reference for what needs to be worked on next. For complex features, it may link to a more detailed status report.
*   **`roadmap_progress.txt`**: This is the master checklist for the entire Laravel-to-Frappe conversion. It provides a granular, feature-by-feature view of the project's overall progress.
*   **Feature Status Reports (e.g., `PARCEL_DELIVERY_STATUS.md`)**: For large, complex features, a dedicated status report may be created. These documents provide a detailed breakdown of the feature, comparing the original implementation with the new one and outlining what is missing.

**Synchronization Guideline:** When you update the status of a task (e.g., in `TODO.md`), you **must** ensure that the corresponding items in `roadmap_progress.txt` are also updated. This ensures that both the high-level and granular views of our progress remain aligned.
