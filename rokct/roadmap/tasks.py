# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import requests
import json

def jules_task_monitor():
    # ... (existing jules_task_monitor function) ...
    pass

def populate_roadmap_with_ai_ideas():
    """
    Periodically polls the Jules API with a set of predefined prompts to
    generate new feature ideas, improvements, and potential bugs.
    """
    # Gating Logic: Do not run if there are already AI-generated ideas pending.
    if frappe.db.exists("Roadmap Feature", {"status": "Ideas", "is_ai_generated": 1}):
        frappe.log_info("Skipping AI idea generation as pending AI ideas already exist.", "Jules Idea Generation")
        return

    # Get API key using the same hybrid logic
    jules_api_key = None
    source_repo = None
    is_control_panel = frappe.conf.get("app_role") == "control_panel"

    if is_control_panel:
        jules_api_key = frappe.conf.get("jules_api_key")
        source_repo = frappe.conf.get("jules_source_repo")
    else:
        # On tenants, this feature runs using the tenant's own key from Jules Settings.
        # It does not use the platform's key, as this is a background process.
        if frappe.db.exists("DocType", "Jules Settings"):
            jules_settings = frappe.get_doc("Jules Settings")
            jules_api_key = jules_settings.get_password("jules_api_key")
            source_repo = jules_settings.source_repository

    if not jules_api_key or not source_repo:
        # This site is not configured for AI idea generation.
        return

    # Define the brainstorming prompts
    prompts = [
        {
            "title": "Suggest New Features",
            "prompt": 'Analyze the entire codebase. Based on the existing features, suggest 3 new, complementary features that would add significant value. For each, provide a title and a brief explanation. Do not write any code. Respond in JSON format: {"ideas": [{"title": "...", "explanation": "..."}]}'
        },
        {
            "title": "Suggest Improvements",
            "prompt": 'Review the existing code. Identify 3 areas that could be improved for performance, user experience, or maintainability. For each, provide a title for the improvement and a brief explanation of what to do. Do not write any code. Respond in JSON format: {"ideas": [{"title": "...", "explanation": "..."}]}'
        },
        {
            "title": "Identify Potential Bugs",
            "prompt": 'Perform a static analysis of the code to identify 3 potential bugs or edge cases that may not be handled correctly. For each, provide a title and a brief explanation of the potential bug. Do not write any code. Respond in JSON format: {"ideas": [{"title": "...", "explanation": "..."}]}'
        }
    ]

    for item in prompts:
        try:
            # Call the Jules API for each prompt
            session_id = _create_jules_session(jules_api_key, source_repo, item["title"], item["prompt"])
            if not session_id:
                continue

            # This is a blocking call for simplicity. A more advanced version might queue this.
            activities = _get_jules_activities(jules_api_key, session_id)
            latest_response = _get_latest_agent_message(activities)

            if latest_response:
                _create_roadmap_features_from_response(latest_response, item["title"])

        except Exception as e:
            frappe.log_error(f"Failed to get AI ideas for prompt '{item['title']}': {e}", "Jules Idea Generation")

def _create_jules_session(api_key, source_repo, title, prompt):
    api_url = "https://jules.googleapis.com/v1alpha/sessions"
    headers = {"Content-Type": "application/json", "X-Goog-Api-Key": api_key}
    data = {
        "prompt": prompt,
        "sourceContext": {"source": source_repo, "githubRepoContext": {"startingBranch": "main"}},
        "title": title,
        "requirePlanApproval": True # We need to review the plan (the JSON response)
    }
    response = requests.post(api_url, json=data, headers=headers, timeout=30)
    response.raise_for_status()
    return response.json().get("name")

def _get_jules_activities(api_key, session_id):
    api_url = f"https://jules.googleapis.com/v1alpha/{session_id}/activities"
    headers = {"X-Goog-Api-Key": api_key}
    # Simple polling loop to wait for a response
    for _ in range(10): # Poll up to 10 times (e.g., 5 minutes)
        frappe.sleep(30)
        response = requests.get(api_url, headers=headers, timeout=15)
        response.raise_for_status()
        activities = response.json().get("activities", [])
        if len(activities) > 1: # The first activity is always the user prompt
            return activities
    return []

def _get_latest_agent_message(activities):
    return next((act.get("agentActivity", {}).get("message") for act in reversed(activities) if act.get("agentActivity")), None)

def _create_roadmap_features_from_response(response_text, task_type):
    try:
        # First, ensure the target Roadmap document exists.
        roadmap_name = "Backend Roadmap"
        if not frappe.db.exists("Roadmap", roadmap_name):
            roadmap_doc = frappe.new_doc("Roadmap")
            roadmap_doc.title = roadmap_name
            roadmap_doc.save(ignore_permissions=True)
            frappe.log_info(f"Created missing Roadmap document: {roadmap_name}", "Jules Idea Generation")

        data = json.loads(response_text)
        roadmap_doc = frappe.get_doc("Roadmap", roadmap_name)

        for idea in data.get("ideas", []):
            feature_doc = frappe.new_doc("Roadmap Feature")
            feature_doc.feature = idea.get("title")
            feature_doc.explanation = idea.get("explanation")
            feature_doc.status = "Ideas"
            feature_doc.is_ai_generated = 1
            feature_doc.type = "Bug" if "bug" in task_type.lower() else "Feature"
            roadmap_doc.append("features", feature_doc)

        roadmap_doc.save(ignore_permissions=True)
        frappe.db.commit()

    except json.JSONDecodeError:
        frappe.log_error(f"Failed to parse JSON response from Jules: {response_text}", "Jules Idea Generation")
    except Exception as e:
        frappe.log_error(f"Failed to create roadmap features: {e}", "Jules Idea Generation")
        frappe.db.rollback()
