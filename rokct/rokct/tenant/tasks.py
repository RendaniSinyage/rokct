# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import json
from frappe.utils import now_datetime
from rokct.tenant.utils import send_tenant_email

def report_active_user_count():
    """
    Counts the number of active users on the tenant site and reports it
    to the control panel for per-seat billing calculations.
    This is run daily by the scheduler on tenant sites.
    """
    if frappe.conf.get("app_role") != "tenant":
        return

    frappe.log("Running Daily User Count Reporting Job...", "User Count Report")

    try:
        # 1. Count active (enabled) users
        active_user_count = frappe.db.count("User", {"enabled": 1})
        frappe.log(f"Found {active_user_count} active users.", "User Count Report")

        # 2. Get credentials to talk to the control panel
        settings = frappe.get_single("Subscription Settings")
        control_plane_url = settings.get("control_plane_url")
        api_secret = settings.get_password("api_secret")

        if not control_plane_url or not api_secret:
            frappe.log_error(
                "Control Plane URL or API Secret is not set in Subscription Settings. Cannot report user count.",
                "User Count Report Failed"
            )
            return

        # 3. Make the API call
        api_url = f"{control_plane_url}/api/method/rokct.rokct.control_panel.api.update_user_count"
        headers = {
            "Content-Type": "application/json",
            "X-Rokct-Secret": api_secret
        }
        data = {
            "user_count": active_user_count
        }

        response = frappe.make_post_request(api_url, headers=headers, data=json.dumps(data))

        if response.get("status") == "success":
            frappe.log(
                f"Successfully reported user count of {active_user_count} to the control panel.",
                "User Count Report"
            )
        else:
            error_message = response.get("message") if isinstance(response, dict) else str(response)
            frappe.log_error(
                f"Failed to report user count to control panel. Status: {response.get('status')}, Message: {error_message}",
                "User Count Report Failed"
            )

    except Exception as e:
        frappe.log_error(
            f"An unexpected error occurred during user count reporting: {e}\n{frappe.get_traceback()}",
            "User Count Report Failed"
        )

def disable_expired_support_users():
    """
    Find and disable temporary support users whose access has expired.
    This is run daily by the scheduler on tenant sites.
    """
    if frappe.conf.get("app_role") != "tenant":
        return

    print("Running Daily Expired Support User Cleanup Job...")

    expired_users = frappe.get_all("User",
        filters={
            "enabled": 1,
            "temporary_user_expires_on": ["<", now_datetime()]
        },
        fields=["name", "email", "first_name"]
    )

    if not expired_users:
        print("No expired support users to disable.")
        return

    print(f"Found {len(expired_users)} expired support users to disable...")

    # Get all system managers to notify them
    system_managers = frappe.get_all("User",
        filters={"role_profile_name": "System Manager", "enabled": 1},
        fields=["email"]
    )
    recipients = [user.email for user in system_managers]

    if not recipients:
        print("No System Managers found to notify.")
        # Still proceed to disable the user, but log it
        frappe.log_error("No System Managers found to notify about expired support user.", "Support User Expiration")


    for user_info in expired_users:
        try:
            user = frappe.get_doc("User", user_info.name)
            user.enabled = 0
            user.save(ignore_permissions=True)

            frappe.db.commit()
            print(f"  - Disabled expired support user: {user.email}")

            if recipients:
                email_context = {
                    "support_user_name": user.full_name,
                    "support_user_email": user.email,
                    "disabled_at": now_datetime().strftime("%Y-%m-%d %H:%M:%S")
                }
                send_tenant_email(
                    recipients=recipients,
                    template="Support User Expired",
                    args=email_context,
                    now=True
                )
                print(f"  - Sent expiration notification to System Managers for {user.email}")

        except Exception as e:
            frappe.db.rollback()
            frappe.log_error(frappe.get_traceback(), f"Failed to disable expired support user {user_info.email}")

    print("Expired Support User Cleanup Job Complete.")

