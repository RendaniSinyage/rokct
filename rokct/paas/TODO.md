# PaaS Module - Pending Tasks

This file tracks important tasks that need to be completed as part of the PaaS module development.

## Incomplete Features

### Parcel Delivery (Comprehensive)
-   **Task:** Implement the full parcel delivery system.
-   **Status:** Partially Implemented
-   **Notes:** The foundational DocTypes (`Parcel Order`, `Parcel Order Setting`) and a basic `create_parcel_order` API exist. The creation API has been enhanced to support item bundling and linking to Sales Orders and Delivery Points. However, the feature is still largely incomplete. The following key components need to be implemented to achieve parity with the original Laravel application:
    -   **Parcel Order Management:** Full CRUD APIs for admins, and management APIs for users and deliverymen (view, update status, etc.).
    -   **Parcel Options:** The entire "Parcel Options" feature, including the DocType and management APIs, is missing.
    -   **Parcel Order Settings:** The `Parcel Order Setting` DocType needs to be expanded, and full CRUD APIs for managing these settings are required.

    **Reference:** For a detailed breakdown of the feature status, see `rokct/paas/PARCEL_DELIVERY_STATUS.md`.

### Re-order / Scheduled Orders
-   **Task:** Implement the feature for creating recurring or scheduled orders.
-   **Status:** To Be Discussed
-   **Notes:** The original Laravel app has a feature for scheduling repeated orders. This is more complex than a simple "re-order now" button and requires further discussion.

### Other Pending REST APIs
-   **Task:** Implement the remaining REST APIs.
-   **Status:** Pending
-   **Notes:** The following REST APIs are still pending: Push Notifications.

## Completed Tasks

### Admin Feature Toggles
-   **Task:** Add a comprehensive set of admin-level feature toggles.
-   **Status:** Partially Implemented
-   **Notes:** Added a full suite of checkboxes to the `PaaS Settings` DocType. The logic for the `Enable Refund System` toggle has been fully implemented across all relevant APIs (create, get, update). The implementation of the other toggles is pending.

### Product Approval Workflow
-   **Task:** Implement an approval workflow for new products.
-   **Status:** Completed
-   **Notes:** A custom field `approval_status` must be added to the `Item` DocType. The `create_seller_product` API now sets this status to `Pending` or `Approved` based on the `auto_approve_products` admin setting. The `get_products` API now only shows `Approved` products.

### Auto-approve Parcel Orders
-   **Task:** Implement auto-approval for parcel orders.
-   **Status:** Completed
-   **Notes:** The `create_parcel_order` API now checks the new `auto_approve_parcel_orders` setting in `PaaS Settings` to determine if a new parcel order should be automatically approved.

### Require Phone Number for Orders
-   **Task:** Add a setting to require a phone number for new orders.
-   **Status:** Completed
-   **Notes:** The `create_order` API now checks the `require_phone_for_order` setting in `PaaS Settings`. If enabled, the API will throw a `ValidationError` if the phone number is missing.

### Auto-approve Categories
-   **Task:** Implement auto-approval for categories.
-   **Status:** Completed
-   **Notes:** The `create_category` API now checks the `auto_approve_categories` setting in `PaaS Settings` to determine if a new category should be `Approved` or `Pending`.

### Subscription Management (Admin & Seller)
-   **Task:** Implement subscription management for both administrators and sellers.
-   **Status:** Completed
-   **Notes:** This feature has been implemented, providing full CRUD capabilities for admins and subscription management for sellers.

### Booking Module (Comprehensive)
-   **Task:** Implement the full booking system, including user, seller, and waiter-facing functionalities.
-   **Status:** Completed
-   **Notes:** The comprehensive booking module has been implemented, including all DocTypes and APIs for Admin, User, Seller, and Waiter roles.

### Auto-approve Orders
-   **Task:** Implement the setting to automatically approve orders.
-   **Status:** Completed
-   **Notes:** Implemented with a hierarchical logic. A global setting in `PaaS Settings` enables the feature platform-wide, and a second setting on the `Shop` DocType allows individual sellers to opt-in. An order is only auto-approved if both the global and the shop-level settings are enabled.

### REST: Branches API
-   **Task:** Implement the Branches API.
-   **Status:** Completed
-   **Notes:** A basic CRUD API for branches has been implemented.

### REST: Orders
-   **Task:** Implement the full functionality of the Orders API.
-   **Status:** Completed
-   **Notes:** The core functionality of the Orders API has been implemented, including creation, listing, status updates, reviews, and cancellation. The re-ordering feature has been deferred for later discussion. Stock replenishment and order calculation logic have been corrected.

### Payment Gateways
-   **Task:** Implement the required payment gateways.
-   **Status:** Completed
-   **Notes:** The following payment gateways have been converted: PayFast, PayPal, PayStack, Flutterwave.

### Coupon Logic
-   **Task:** Implement Coupon Usage Recording.
-   **Status:** Completed
-   **Details:** The `check_coupon` API has been updated to prevent a user from using the same coupon code multiple times. The logic to *record* that a coupon has been used is present in the `create_order` API.
-   **Note:** This task was marked as pending, but the implementation was already present.

### Payment Gateway Callbacks
-   **Task:** Make Payment Gateway Redirect URLs Configurable.
-   **Status:** Completed
-   **Details:** The callback functions for Flutterwave, PayPal, and PayFast now use configurable redirect URLs from the `Payment Gateway` settings.
-   **Files modified:** `rokct/paas/api.py`.