# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document
import requests

class RoadmapFeature(Document):
    def get_indicator(self, doc):
        if doc.status == "Done" and doc.type == "Bug":
            return ("Red", "bug", "Bug")
        return None

@frappe.whitelist()
def assign_to_jules(docname, feature, explanation):
    """
    Assigns a roadmap feature to the Jules AI assistant using a hybrid key model.
    """
    try:
        jules_api_key = None
        source_repo = None

        # Step 1: Determine which API key to use
        is_control_panel = frappe.conf.get("app_role") == "control_panel"

        if is_control_panel:
            jules_api_key = frappe.conf.get("jules_api_key")
            source_repo = frappe.conf.get("jules_source_repo")
        else:
            subscription = frappe.call('rokct.rokct.tenant.api.get_subscription_details')
            if subscription and subscription.get('enable_ai_developer_features'):
                jules_api_key = subscription.get("jules_api_key")
                source_repo = subscription.get("jules_source_repo")
            else:
                jules_settings = frappe.get_doc("Jules Settings")
                jules_api_key = jules_settings.get_password("jules_api_key")
                source_repo = jules_settings.source_repository

        if not jules_api_key or not source_repo:
            frappe.throw("Jules API key or Source Repository is not configured for this site. Please configure it in Jules Settings or contact support.")

        # Step 2: Prepare and call the Jules API
        api_url = "https://jules.googleapis.com/v1alpha/sessions"
        prompt = f"**Task:** {feature}\n\n**Details:**\n{explanation}"

        headers = {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": jules_api_key
        }

        data = {
            "prompt": prompt,
            "sourceContext": {
                "source": source_repo,
                "githubRepoContext": {
                    "startingBranch": "main"
                }
            },
            "title": feature,
            "requirePlanApproval": False
        }

        response = requests.post(api_url, json=data, headers=headers, timeout=30)
        response.raise_for_status()

        session_data = response.json()
        session_id = session_data.get("name")

        if not session_id:
            frappe.throw("Failed to create a Jules session. No session ID returned.")

        # Step 3: Update the document
        feature_doc = frappe.get_doc("Roadmap Feature", docname)
        feature_doc.db_set('status', 'Doing')
        feature_doc.db_set('ai_status', 'Assigned')
        feature_doc.db_set('jules_session_id', session_id)

        frappe.msgprint(f"Task '{feature}' has been successfully assigned to Jules.")
        return "Success"

    except requests.exceptions.RequestException as e:
        frappe.log_error(f"Jules API request failed: {e}", "Jules Assignment Error")
        frappe.throw(f"Failed to communicate with the Jules API: {e}")
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Jules Assignment Error")
        frappe.throw(f"An unexpected error occurred: {e}")
