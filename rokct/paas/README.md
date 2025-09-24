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

