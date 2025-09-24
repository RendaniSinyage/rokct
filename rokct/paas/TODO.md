# PaaS Module - Pending Tasks

This file tracks important tasks that need to be completed as part of the PaaS module development.

## REST: Branches API
- **Task:** Implement the Branches API.
- **Status:** Completed
- **Notes:** A basic CRUD API for branches has been implemented.

## REST: Orders
- **Task:** Implement the full functionality of the Orders API.
- **Status:** Completed
- **Notes:** The core functionality of the Orders API has been implemented, including creation, listing, status updates, reviews, and cancellation. The re-ordering feature has been deferred for later discussion. Stock replenishment and order calculation logic have been corrected.

## Payment Gateways
- **Task:** Implement the required payment gateways.
- **Status:** Completed
- **Notes:** The following payment gateways have been converted: PayFast, PayPal, PayStack, Flutterwave.

## Future Features (To Be Discussed)
- **Re-order / Scheduled Orders:** The original Laravel app has a feature for scheduling repeated orders. This is more complex than a simple "re-order now" button and requires further discussion.
- **Auto-approve Orders:** The original Laravel app has a setting for auto-approving orders. This needs to be implemented.
- **Other REST APIs:** The following REST APIs are still pending: Push Notifications, Parcel Orders, Delivery Points.

## Coupon Logic
- **Task:** Implement Coupon Usage Recording.
- **Status:** Completed
- **Details:** The `check_coupon` API has been updated to prevent a user from using the same coupon code multiple times. The logic to *record* that a coupon has been used is present in the `create_order` API.
- **Note:** This task was marked as pending, but the implementation was already present.

## Payment Gateway Callbacks
- **Task:** Make Payment Gateway Redirect URLs Configurable.
- **Status:** Completed
- **Details:** The callback functions for Flutterwave, PayPal, and PayFast now use configurable redirect URLs from the `Payment Gateway` settings.
- **Files modified:** `rokct/paas/api.py`.

