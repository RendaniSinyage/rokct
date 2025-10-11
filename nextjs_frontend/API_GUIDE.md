# Frontend API Integration Guide

This document outlines the API workflow for a decoupled frontend interacting with the ROKCT multi-site SaaS platform.

## Core Architecture

The backend consists of two types of sites:

1.  **The Control Panel (`platform.rokct.ai`):** A single, central site that handles user registration and subscription management.
2.  **Tenant Sites (`[unique-id].client.rokct.ai`):** An isolated, individual site created for each customer to house their business data.

The frontend's primary responsibility is to direct API calls to the correct site.

---

## 1. User Signup & Provisioning

This is the only time the frontend needs to talk to the **Control Panel**.

-   **Endpoint:** `POST https://platform.rokct.ai/api/method/rokct.control_panel.provisioning.provision_new_tenant`
-   **Method:** `POST`
-   **Description:** This single API call handles the entire backend process: it creates a `Customer` record, a `Company Subscription`, generates a unique site for the tenant, installs the necessary apps, and prepares it for the first user.
-   **Request Body (JSON):**
    ```json
    {
        "plan": "your_plan_name",
        "email": "user@example.com",
        "password": "user_password",
        "first_name": "John",
        "last_name": "Doe",
        "company_name": "Example Corp",
        "currency": "USD",
        "country": "United States",
        "industry": "Software"
    }
    ```
-   **Successful Response (200 OK):**
    ```json
    {
        "status": "success",
        "message": "Site tenant-a.client.rokct.ai is being set up. You will receive an email shortly.",
        "site_name": "tenant-a.client.rokct.ai"
    }
    ```

### Frontend Responsibility

Upon receiving a successful response, the frontend must **save the `site_name`** in its own user database, associated with that user's account. This unique URL is the key to all future interactions for that user.

---

## 2. User Login

Login happens directly on the user's dedicated **Tenant Site**.

-   **Endpoint:** `POST https://[site_name]/api/method/login`
-   **Method:** `POST`
-   **Description:** Authenticates the user against their own site.
-   **Request Body (JSON):**
    ```json
    {
        "usr": "user@example.com",
        "pwd": "user_password"
    }
    ```
-   **Successful Response (200 OK):**
    ```json
    {
        "message": "Logged In",
        "home_page": "/app",
        "full_name": "John Doe",
        "api_key": "xxxxxxxxxx",
        "api_secret": "xxxxxxxxxx"
    }
    ```

### Frontend Responsibility

The frontend must securely store the returned `api_key` and `api_secret`. These tokens are required to authenticate all subsequent API calls for this user.

---

## 3. Performing Business Tasks

This section covers common tasks performed on the **Tenant Site**.

### Creating a One-Time or Recurring Invoice

Instead of using the standard `/api/resource/Sales%20Invoice` endpoint, a unified custom API has been created to handle both one-time and recurring invoices.

-   **Endpoint:** `POST https://[site_name]/api/method/rokct.tenant.api.create_sales_invoice`
-   **Method:** `POST`
-   **Authentication:** Requires the standard `Authorization: token [api_key]:[api_secret]` header.
-   **Description:** Creates a new Sales Invoice. If recurring parameters are provided, it will also create an "Auto Repeat" schedule for the invoice.

#### Example 1: Creating a One-Time Invoice
-   **Request Body (JSON):**
    ```json
    {
        "invoice_data": {
            "doctype": "Sales Invoice",
            "customer": "CUSTOMER-0001",
            "due_date": "2025-12-31",
            "items": [{"item_code": "ITEM-001", "qty": 10, "rate": 100}]
        }
    }
    ```

#### Example 2: Creating a Recurring Monthly Invoice
-   **Request Body (JSON):**
    ```json
    {
        "invoice_data": {
            "doctype": "Sales Invoice",
            "customer": "CUSTOMER-0002",
            "due_date": "2025-10-31",
            "items": [{"item_code": "ITEM-002", "qty": 1, "rate": 500}]
        },
        "recurring": true,
        "frequency": "Monthly",
        "end_date": "2026-09-30"
    }
    ```

---

## 5. Checking Subscription Status & Enabled Modules

The `on_login` hook on the backend automatically syncs the user's permissions. However, the frontend needs a way to know which UI elements to show or hide based on the user's subscription plan. This is done by calling a secure proxy API on the tenant site.

-   **Endpoint:** `POST https://[site_name]/api/method/rokct.tenant.api.get_subscription_details`
-   **Method:** `POST`
-   **Description:** This is a secure proxy API on the tenant site. The frontend should call this endpoint. It is simple to use as it doesn't require any special authentication other than the standard user session. The backend handles the secure communication with the control panel.
-   **Authentication:** Requires the standard `Authorization: token [api_key]:[api_secret]` header.
-   **Successful Response (200 OK):**
    ```json
    {
        "status": "Active",
        "plan": "Pro Plan",
        "trial_ends_on": null,
        "next_billing_date": "2025-10-31",
        "modules": ["Accounts", "Stock", "Projects", "CRM"],
        "max_companies": 5
    }
    ```

### Frontend Responsibility

The frontend should use the `modules` array in this response to dynamically render the UI. For example, if `"Projects"` is in the `modules` array, show the "Projects" section in the navigation.

---

## 6. Interacting with the Brain Module (For AI Agents)

The `brain` module provides endpoints for an authenticated AI agent (like Jules) to interact with the application's memory (`Engrams`).

### Querying a Document's Memory

-   **Endpoint:** `POST https://[site_name]/api/method/rokct.brain.api.query`
-   **Method:** `POST`
-   **Authentication:** Requires the standard `Authorization: token [api_key]:[api_secret]` header for the AI user.
-   **Description:** Fetches the `Engram` (memory) for a specific document. This is the key endpoint for powering the **Proactive Cognitive Assistant** workflow by retrieving a user's past activity.
-   **Request Body (JSON):**
    ```json
    {
        "doctype": "Sales Invoice",
        "name": "ACC-SINV-2025-00001"
    }
    ```
-   **Successful Response (200 OK):**
    ```json
    {
        "name": "Sales Invoice-ACC-SINV-2025-00001",
        "reference_doctype": "Sales Invoice",
        "reference_name": "ACC-SINV-2025-00001",
        "summary": "Created by Test User on 2025-10-11.\nUpdated by AI User on 2025-10-11.",
        "involved_users": "AI User, Test User",
        "last_activity_date": "2025-10-11 09:30:00",
        "brain_version": "2.5.0"
    }
    ```

### Recording a Custom Event

This endpoint is used to log events that are not captured by standard document hooks, such as a failed action.

-   **Endpoint:** `POST https://[site_name]/api/method/rokct.brain.api.record_event`
-   **Method:** `POST`
-   **Authentication:** Requires the standard `Authorization: token [api_key]:[api_secret]` header for the AI user.
-   **Description:** Records a custom event message and associates it with a specific document's memory.
-   **Request Body (JSON):**
    ```json
    {
        "message": "Action Failed: Insufficient Permissions",
        "reference_doctype": "Sales Invoice",
        "reference_name": "ACC-SINV-2025-00001"
    }
    ```
-   **Successful Response (200 OK):**
    ```json
    {
        "status": "success",
        "message": "Event recorded."
    }
    ```

### Recording a Chat Summary

This endpoint is used by the frontend to store a permanent memory of a user's conversation with the AI.

-   **Endpoint:** `POST https://[site_name]/api/method/rokct.brain.api.record_chat_summary`
-   **Method:** `POST`
-   **Authentication:** Requires the standard `Authorization: token [api_key]:[api_secret]` header for the user.
-   **Description:** Creates a new `Engram` record from an AI-generated summary of a chat.
-   **Request Body (JSON):**
    ```json
    {
        "summary_text": "User asked to create an invoice for Customer Y. Action was successful (INV-00124).",
        "reference_doctype": "Customer",
        "reference_name": "CUSTOMER-001"
    }
    ```
-   **Successful Response (200 OK):**
    ```json
    {
        "status": "success",
        "message": "Chat summary recorded in Engram Customer-CUSTOMER-001."
    }
    ```

---

## Summary of Frontend Logic

1.  **On Signup:** Call the Control Panel to provision a new site. Save the returned `site_name`.
2.  **On Login:** Use the saved `site_name` to log in to the Tenant Site. Save the `api_key` and `api_secret`.
3.  **After Login:** Call the new `get_subscription_details` proxy API on the tenant site to get the list of enabled `modules` and configure the UI accordingly.
4.  **For All Other Actions:** Use the saved `site_name` and authentication tokens to call the appropriate APIs on the Tenant Site.
