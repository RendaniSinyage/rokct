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
        # On a tenant site, use the key from the local Jules Settings.
        if frappe.db.exists("DocType", "Jules Settings"):
            jules_settings = frappe.get_doc("Jules Settings")
            jules_api_key = jules_settings.get_password("jules_api_key")

    if not jules_api_key:
        # No key is configured on this site, so the monitor cannot proceed.
        return

    # Step 2: Get all features assigned to Jules on this site.
    assigned_features = frappe.get_all("Roadmap Feature",
        filters={"ai_status": ["in", ["Assigned", "In Progress"]]},
        fields=["name", "jules_session_id"]
    )

    if not assigned_features:
        return

    # Step 3: Loop through each task and check for updates.
    for item in assigned_features:
        session_id = item.get("jules_session_id")
        if not session_id:
            continue

        doc = frappe.get_doc("Roadmap Feature", item.get("name"))

        try:
            api_url = f"https://jules.googleapis.com/v1alpha/{session_id}/activities"
            headers = {"X-Goog-Api-Key": jules_api_key}

            response = requests.get(api_url, headers=headers, timeout=15)
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
