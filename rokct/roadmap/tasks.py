# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import requests

def jules_task_monitor():
    """
    Monitors the status of tasks assigned to the Jules AI assistant.
    This script runs on every site and uses the credentials configured on that site.
    """
    jules_api_key = None
    is_control_panel = frappe.conf.get("app_role") == "control_panel"

    # Step 1: Get the appropriate API key for the current site.
    if is_control_panel:
        jules_api_key = frappe.conf.get("jules_api_key")
    else:
        # On a tenant site, make a secure external HTTP request to the control panel
        control_plane_url = frappe.conf.get("control_plane_url")
        api_secret = frappe.conf.get("api_secret")

        if not control_plane_url or not api_secret:
            # If tenant isn't configured for control panel communication, only check for local key.
            if frappe.db.exists("DocType", "Jules Settings"):
                jules_settings = frappe.get_doc("Jules Settings")
                jules_api_key = jules_settings.get_password("jules_api_key")
        else:
            try:
                scheme = frappe.conf.get("control_plane_scheme", "https")
                api_url = f"{scheme}://{control_plane_url}/api/method/rokct.rokct.control_panel.api.get_subscription_status"
                headers = {"X-Rokct-Secret": api_secret}

                response = requests.post(api_url, headers=headers, timeout=15)
                response.raise_for_status()
                subscription_details = response.json().get("message", {})

                if subscription_details and subscription_details.get('enable_ai_developer_features'):
                    jules_api_key = subscription_details.get("jules_api_key")
                else:
                    # Fallback to local settings if feature not enabled
                    if frappe.db.exists("DocType", "Jules Settings"):
                        jules_settings = frappe.get_doc("Jules Settings")
                        jules_api_key = jules_settings.get_password("jules_api_key")

            except Exception as e:
                 frappe.log_error(f"Could not fetch subscription details from control panel during task monitoring: {e}", "Jules Monitor Error")
                 # Fallback to local settings if the API call fails
                 if frappe.db.exists("DocType", "Jules Settings"):
                    jules_settings = frappe.get_doc("Jules Settings")
                    jules_api_key = jules_settings.get_password("jules_api_key")

    if not jules_api_key:
        # No key configured for this site, so the monitor cannot proceed.
        return

    # Step 2: Get all features assigned to Jules on this site.
    assigned_features = frappe.get_all("Roadmap Feature",
        filters={"ai_status": ["in", ["Assigned", "In Progress"]]},
        fields=["name", "jules_session_id"]
    )

    if not assigned_features:
        return

    # Step 3: Loop through each task and check for updates using the key we found.
    for item in assigned_features:
        session_id = item.get("jules_session_id")
        if not session_id:
            continue

        doc = frappe.get_doc("Roadmap Feature", item.get("name"))

        try:
            jules_api_url = f"https://jules.googleapis.com/v1alpha/{session_id}/activities"
            headers = {"X-Goog-Api-Key": jules_api_key}

            response = requests.get(jules_api_url, headers=headers, timeout=15)
            response.raise_for_status()

            activities_data = response.json()
            activities = activities_data.get("activities", [])

            if not activities:
                continue

            latest_agent_activity = next((act.get("agentActivity") for act in reversed(activities) if act.get("agentActivity")), None)

            if not latest_agent_activity:
                continue

            latest_message = latest_agent_activity.get("message", "No recent updates.")
            doc.db_set("ai_work_log", latest_message)

            if "pull request" in latest_message.lower():
                doc.db_set("ai_status", "PR Ready")
            elif doc.ai_status == "Assigned":
                 doc.db_set("ai_status", "In Progress")

        except Exception as e:
            frappe.log_error(f"Jules monitor failed for session {session_id}: {frappe.get_traceback()}", "Jules Monitor Error")
            doc.db_set("ai_status", "Error")
            doc.db_set("ai_work_log", f"An error occurred during monitoring: {e}")
