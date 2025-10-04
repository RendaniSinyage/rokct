# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import requests

def jules_task_monitor():
    """
    Monitors the status of tasks assigned to the Jules AI assistant and updates
    the Roadmap Feature document with the latest progress.
    """
    # Get all features that are currently assigned to Jules
    assigned_features = frappe.get_all("Roadmap Feature",
        filters={"ai_status": ["in", ["Assigned", "In Progress"]]},
        fields=["name", "jules_session_id", "feature"]
    )

    if not assigned_features:
        return

    for item in assigned_features:
        session_id = item.get("jules_session_id")
        if not session_id:
            continue

        doc = frappe.get_doc("Roadmap Feature", item.get("name"))
        jules_api_key = None

        try:
            # Step 1: Determine which API key to use (mirroring the assignment logic)
            is_control_panel = frappe.conf.get("app_role") == "control_panel"

            if is_control_panel:
                jules_api_key = frappe.conf.get("jules_api_key")
            else:
                subscription = frappe.call('rokct.rokct.tenant.api.get_subscription_details')
                if subscription and subscription.get('enable_ai_developer_features'):
                    jules_api_key = subscription.get("jules_api_key")
                else:
                    jules_settings = frappe.get_doc("Jules Settings")
                    jules_api_key = jules_settings.get_password("jules_api_key")

            if not jules_api_key:
                # Log an error but continue to the next item, as other tasks might have valid keys
                frappe.log_error(f"Jules API key not found for task {item.get('name')}", "Jules Monitor Error")
                continue

            # Step 2: Prepare and call the Jules API to get activities
            api_url = f"https://jules.googleapis.com/v1alpha/{session_id}/activities"
            headers = {"X-Goog-Api-Key": jules_api_key}

            response = requests.get(api_url, headers=headers, timeout=15)
            response.raise_for_status()

            activities_data = response.json()
            activities = activities_data.get("activities", [])

            if not activities:
                continue

            # Step 3: Parse the latest activity and update the document
            latest_agent_activity = next((act.get("agentActivity") for act in reversed(activities) if act.get("agentActivity")), None)

            if not latest_agent_activity:
                continue

            latest_message = latest_agent_activity.get("message", "No recent updates.")
            doc.db_set("ai_work_log", latest_message)

            if "pull request" in latest_message.lower():
                doc.db_set("ai_status", "PR Ready")
                # In a real implementation, we would parse the URL from the message.
                # For now, we'll just update the status.
            elif doc.ai_status == "Assigned":
                 doc.db_set("ai_status", "In Progress")

        except Exception as e:
            # If any error occurs for one task, log it and move to the next
            frappe.log_error(f"Jules monitor failed for session {session_id}: {frappe.get_traceback()}", "Jules Monitor Error")
            doc.db_set("ai_status", "Error")
            doc.db_set("ai_work_log", f"An error occurred during monitoring: {e}")
