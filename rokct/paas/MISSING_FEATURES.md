# Missing PaaS Module Features

This document outlines the features that were present in the original Laravel application (`rokct/paas/juvo/backend`) but have not yet been fully implemented in the Frappe `paas` module. This report is based on a detailed, controller-by-controller analysis of the Laravel backend.

## 1. Booking Module (Comprehensive)

The most significant missing feature is the comprehensive **Booking Module**. While the `roadmap_progress.txt` indicates that the booking module has been implemented for the Admin dashboard, this appears to be limited to basic CRUD operations. The vast majority of user-facing, seller-facing, and waiter-facing functionalities are absent.

The original Laravel application had a rich set of booking features, as defined in `rokct/paas/juvo/backend/routes/booking.php`. The following key components have not been ported to the Frappe `paas` module:

-   **User Booking Management:**
    -   Users cannot create, view, or manage their own bookings.
    -   The `my-bookings` API endpoint for users is missing.
-   **Seller Booking Management:**
    -   Sellers cannot manage bookings, user bookings, shop sections, or tables.
    -   The entire suite of seller-side booking management tools is absent.
-   **Waiter Booking Management:**
    -   Waiters have no interface to manage or view bookings.
-   **Shop Sections and Tables:**
    -   The underlying models and APIs for `Shop Sections` and `Tables` are missing. These are essential for the booking system to function.
-   **Booking Availability:**
    -   The logic for managing booking availability, including working days, closed days, and disabled dates for tables, has not been implemented.

## 2. Subscription Management (Admin & Seller)

-   **Description:** The original Laravel application provided both sellers and administrators with the ability to manage subscriptions. This functionality is completely missing from the Frappe `paas` module. The `roadmap_progress.txt` does not list this feature as implemented, skipped, or pending for either the Admin or Seller Dashboards.
-   **Laravel Locations:**
    -   **Admin:** `rokct/paas/juvo/backend/app/Http/Controllers/API/v1/Dashboard/Admin/SubscriptionController.php`
    -   **Seller:** `rokct/paas/juvo/backend/app/Http/Controllers/API/v1/Dashboard/Seller/SubscriptionController.php`

## 3. Recurring and Scheduled Orders

-   **Description:** The original Laravel application had a feature for creating recurring or scheduled orders. This functionality has not been implemented in the Frappe `paas` module.
-   **Status:** This feature was noted as "To Be Discussed" in the `rokct/paas/TODO.md` file, indicating that it is a known missing feature.

## 4. Intentionally Excluded Features

The following features were present in the original Laravel application but have been intentionally excluded from the Frappe `paas` module, as noted in the `roadmap_progress.txt` file:

-   **Loan Management:** The entire loan management module, including loan applications and documents, has been excluded.
-   **ERPGo Integration:** The integration with ERPGo has been deprecated and is no longer needed.
-   **Specific Webhooks:** The following webhooks have been excluded: Razorpay, MyFatoorah, Iyzico, MercadoPago, PayTabs, Moyasar, ZainCash, Mollie, Maksekeskus, and Telegram.
-   **Resource APIs:** Several resource-related APIs, such as those for Apps, Roadmap Versions, and various operational metrics (Expenses, Energy Consumption, etc.), have been moved to the core `rokct` app or excluded.

## 5. Parcel Delivery (Comprehensive)

While the core APIs for creating and listing parcel orders exist, key business logic and management functionalities are missing, as noted in the `PARCEL_DELIVERY_STATUS.md` file. The following specific features have not been implemented in the existing APIs:

-   **Parcel Order State Machine:**
    -   **Location:** `rokct/paas/api/parcel/parcel.py` (in `update_parcel_status`)
    -   **Description:** There is no validation logic to enforce a valid state machine for parcel orders. The `update_parcel_status` function allows the status to be changed to any arbitrary string, which could lead to invalid states (e.g., from "Delivered" back to "New").

-   **Role-Based Authorization for Status Updates:**
    -   **Location:** `rokct/paas/api/parcel/parcel.py` (in `update_parcel_status`)
    -   **Description:** The authorization logic for updating a parcel's status is incomplete. It only allows the creator of the order to change the status, which is insufficient for a real-world workflow where administrators, sellers, and delivery personnel would need to perform updates.