# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe

# Import whitelisted methods from other files to expose them under a single API namespace
from .billing import save_payment_method
from .provisioning import provision_new_tenant
from .support import grant_support_access, revoke_support_access

# This is to make linters happy
__all__ = [
    "get_subscription_status",
    "save_payment_method",
    "provision_new_tenant",
    "grant_support_access",
    "revoke_support_access",
    "mark_subscription_as_verified",
    "resend_welcome_email",
    "approve_migration",
]


@frappe.whitelist()
def approve_migration(subscription_id):
    """
    Sets the `migration_approved` flag for a given subscription.
    Only callable by a System Manager.
    """
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", frappe.PermissionError)

    if not subscription_id:
        frappe.throw("Subscription ID is required.", title="Missing Information")

    try:
        subscription = frappe.get_doc("Company Subscription", subscription_id)
        subscription.migration_approved = 1
        subscription.save(ignore_permissions=True)
        frappe.db.commit()
        return {"status": "success", "message": f"Migration approved for {subscription.site_name}."}
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Approve Migration Failed")
        frappe.throw(f"An error occurred while approving the migration: {e}")


@frappe.whitelist()
def mark_subscription_as_verified():
    """
    Called by a tenant site to mark its subscription as email-verified.
    This is a secure backend-to-backend call.
    """
    # This API should only ever run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")

    # 1. Get tenant identity and secret from request
    tenant_site = frappe.local.request.host
    received_secret = frappe.local.request.headers.get("X-Rokct-Secret")

    if not tenant_site:
        frappe.throw("Could not identify tenant site from request.")
    if not received_secret:
        frappe.throw("Missing or invalid X-Rokct-Secret header.")

    # 2. Find the subscription and get the stored secret
    subscription_name = frappe.db.get_value("Company Subscription", {"site_name": tenant_site}, "name")
    if not subscription_name:
        frappe.throw(f"No subscription found for site {tenant_site}")

    stored_secret = frappe.utils.get_password(doctype="Company Subscription", name=subscription_name, fieldname="api_secret")

    # 3. Validate the secret
    if not stored_secret or received_secret != stored_secret:
        frappe.throw("Authentication failed.")

    # 4. If authentication is successful, update the subscription
    try:
        subscription = frappe.get_doc("Company Subscription", subscription_name)
        if not subscription.email_verified_on:
            subscription.email_verified_on = frappe.utils.now_datetime()
            subscription.save(ignore_permissions=True)
            frappe.db.commit()
        return {"status": "success", "message": "Subscription marked as verified."}
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Mark Subscription as Verified Failed")
        frappe.throw("An error occurred while updating the subscription.")


@frappe.whitelist()
def get_subscription_status():
    """
    Called by a tenant site to get its current subscription status.
    Uses the request's origin (the site name) to identify the tenant and a shared secret for auth.
    """
    # This API should only ever run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")

    # 1. Get tenant identity and secret from request
    tenant_site = frappe.local.request.host
    received_secret = frappe.local.request.headers.get("X-Rokct-Secret")

    if not tenant_site:
        frappe.throw("Could not identify tenant site from request.")
    if not received_secret:
        frappe.throw("Missing or invalid X-Rokct-Secret header.")

    # 2. Find the subscription and get the stored secret
    subscription_name = frappe.db.get_value("Company Subscription", {"site_name": tenant_site}, "name")
    if not subscription_name:
        frappe.throw(f"No subscription found for site {tenant_site}")

    stored_secret = frappe.utils.get_password(doctype="Company Subscription", name=subscription_name, fieldname="api_secret")

    # 3. Validate the secret
    if not stored_secret or received_secret != stored_secret:
        frappe.throw("Authentication failed.")

    # 4. If authentication is successful, return the data
    subscription = frappe.get_doc("Company Subscription", subscription_name)
    plan = frappe.get_doc("Subscription Plan", subscription.plan)
    settings = frappe.get_doc("Subscription Settings")

    return {
        "status": subscription.status,
        "plan": subscription.plan,
        "trial_ends_on": subscription.trial_ends_on,
        "next_billing_date": subscription.next_billing_date,
        "modules": [p.module for p in plan.get("modules", [])],
        "max_companies": getattr(plan, 'max_companies', 1), # Get override from plan, default to 1
        "subscription_cache_duration": settings.subscription_cache_duration or 86400
    }


@frappe.whitelist()
def resend_welcome_email(subscription_id: str):
    """
    Resends the welcome email to the primary user of a tenant site.
    """
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", frappe.PermissionError)

    if not subscription_id:
        frappe.throw("Subscription ID is required.", title="Missing Information")

    subscription = frappe.get_doc("Company Subscription", subscription_id)
    if not subscription or not subscription.site_name:
        frappe.throw(f"Subscription {subscription_id} not found or does not have a site name.")

    site_name = subscription.site_name
    api_secret = frappe.utils.get_password(doctype="Company Subscription", name=subscription.name, fieldname="api_secret")

    try:
        # Call the tenant to get the user's details
        scheme = frappe.conf.get("tenant_site_scheme", "http")
        tenant_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.get_welcome_email_details"
        headers = {
            "Content-Type": "application/json",
            "X-Rokct-Secret": api_secret
        }
        response = frappe.make_post_request(tenant_url, headers=headers)

        if response.get("status") != "success":
            raise frappe.ValidationError(f"Failed to get user details from tenant: {response.get('message')}")

        user_details = response.get("message")

        # Send the welcome email
        verification_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.verify_my_email?token={user_details['email_verification_token']}"
        email_context = {
            "first_name": user_details["first_name"],
            "company_name": subscription.customer,
            "verification_url": verification_url
        }
        frappe.sendmail(
            recipients=[user_details["email"]],
            template="New User Welcome",
            args=email_context,
            now=True
        )
        return {"status": "success", "message": f"Welcome email sent to {user_details['email']}."}

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), f"Failed to resend welcome email for {site_name}")
        frappe.throw(f"An error occurred while trying to resend the welcome email: {e}")

