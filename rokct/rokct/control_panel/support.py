# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
# This file will contain APIs related to support access.
import frappe
import json
import re

def _sanitize_for_email(text: str) -> str:
    """
    Sanitizes a string to be safely used in the local part of an email address.
    - Converts to lowercase
    - Replaces spaces and underscores with hyphens
    - Removes all other non-alphanumeric characters (except hyphens)
    - Truncates to a reasonable length
    """
    if not text:
        return ""
    text = text.lower().strip()
    text = re.sub(r'[\s_]+', '-', text)
    text = re.sub(r'[^a-z0-9-]', '', text)
    return text[:30]


@frappe.whitelist()
def grant_support_access(subscription_id: str, reason: str):
    """
    Creates a temporary support user on a tenant site with a descriptive name.
    """
    # This API should only ever run on the control panel and only by a System Manager.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", title="Not Authorized")

    # --- Input Validation ---
    if not all([subscription_id, reason, reason.strip()]):
        frappe.throw("Subscription ID and a valid Reason are required.", title="Missing Information")
    if not frappe.db.exists("Company Subscription", subscription_id):
        frappe.throw(f"Subscription '{subscription_id}' not found.", title="Not Found")
    # --- End Validation ---

    # 1. Get tenant details from the subscription
    subscription = frappe.get_doc("Company Subscription", subscription_id)
    if not subscription or not subscription.site_name:
        frappe.throw(f"Subscription {subscription_id} not found or does not have a site name.")

    site_name = subscription.site_name
    api_secret = frappe.utils.get_password(doctype="Company Subscription", name=subscription.name, fieldname="api_secret")

    # 2. Get agent details and sanitize inputs
    agent_id = _sanitize_for_email(frappe.session.user)
    sanitized_reason = _sanitize_for_email(reason)
    support_email_domain = frappe.db.get_single_value("Subscription Settings", "support_email_domain") or "rokct.ai"


    # 3. Call the tenant API to create the temporary user
    try:
        scheme = frappe.conf.get("tenant_site_scheme", "http")
        tenant_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.create_temporary_support_user"
        headers = {
            "Content-Type": "application/json",
            "X-Rokct-Secret": api_secret
        }
        data = {
            "agent_id": agent_id,
            "reason": sanitized_reason,
            "support_email_domain": support_email_domain
        }

        response = frappe.make_post_request(tenant_url, headers=headers, data=json.dumps(data))

        if response.get("status") != "success":
            raise frappe.ValidationError(f"Failed to create support user on tenant: {response.get('message')}")

        # 4. Return the temporary credentials to the admin
        return response.get("message")

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), f"Failed to grant support access for {site_name}")
        frappe.throw(f"An error occurred while trying to grant support access: {e}")

@frappe.whitelist()
def revoke_support_access(subscription_id, support_user_email):
    """
    Disables a temporary support user on a tenant site.
    """
    # This API should only ever run on the control panel and only by a System Manager.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", title="Not Authorized")

    # --- Input Validation ---
    if not subscription_id or not support_user_email:
        frappe.throw("Subscription ID and Support User Email are required.", title="Missing Information")

    if not frappe.db.exists("Company Subscription", subscription_id):
        frappe.throw(f"Subscription '{subscription_id}' not found.", title="Not Found")

    from frappe.utils import validate_email_address
    try:
        validate_email_address(support_user_email, throw=True)
    except frappe.exceptions.ValidationError:
        frappe.throw("You must provide a valid email address for the support user.", title="Invalid Email")
    # --- End Validation ---

    # 1. Get tenant details from the subscription
    subscription = frappe.get_doc("Company Subscription", subscription_id)
    if not subscription or not subscription.site_name:
        frappe.throw(f"Subscription {subscription_id} not found or does not have a site name.")

    site_name = subscription.site_name
    api_secret = frappe.utils.get_password(doctype="Company Subscription", name=subscription.name, fieldname="api_secret")

    # 2. Call the tenant API to disable the temporary user
    try:
        scheme = frappe.conf.get("tenant_site_scheme", "http")
        tenant_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.disable_temporary_support_user"
        headers = {
            "Content-Type": "application/json",
            "X-Rokct-Secret": api_secret
        }
        data = {
            "support_user_email": support_user_email
        }

        response = frappe.make_post_request(tenant_url, headers=headers, data=json.dumps(data))

        if response.get("status") != "success":
            raise frappe.ValidationError(f"Failed to disable support user on tenant: {response.get('message')}")

        return response.get("message")

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), f"Failed to revoke support access for {site_name}")
        frappe.throw(f"An error occurred while trying to revoke support access: {e}")

