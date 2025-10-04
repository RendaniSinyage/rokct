# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import requests
import json

def populate_roadmap_with_ai_ideas():
    """
    Orchestrator function that iterates through all defined roadmaps and
    triggers the AI idea generation process for each one.
    This function is designed to be the main entry point for the scheduled task.
    """
    try:
        jules_api_key = _get_api_key()
        if not jules_api_key:
            frappe.log_info("Jules API key not configured. Skipping idea generation.", "Jules Idea Generation")
            return

        roadmaps = frappe.get_all("Roadmap", filters={"source_repository": ["is", "set"]}, fields=["name", "source_repository"])

        for roadmap in roadmaps:
            roadmap_name = roadmap.get("name")
            source_repo = roadmap.get("source_repository")

            # Per-roadmap gating logic
            if frappe.db.exists("Roadmap Feature", {"parent": roadmap_name, "status": "Ideas", "is_ai_generated": 1}):
                frappe.log_info(f"Skipping AI idea generation for '{roadmap_name}' as pending AI ideas already exist.", "Jules Idea Generation")
                continue

            try:
                generated_ideas = _generate_ideas_for_repo(source_repo, jules_api_key)
                if generated_ideas:
                    _save_ideas_to_roadmap(roadmap_name, generated_ideas)
            except Exception as e:
                frappe.log_error(f"Failed to process roadmap '{roadmap_name}': {e}", "Jules Idea Generation")

    except Exception as e:
        frappe.log_error(f"The AI idea generation task failed globally: {e}", "Jules Idea Generation")

def _get_api_key():
    """Retrieves the Jules API key from site configuration."""
    if frappe.conf.get("app_role") == "control_panel":
        return frappe.conf.get("jules_api_key")

    if frappe.db.exists("DocType", "Jules Settings"):
        jules_settings = frappe.get_doc("Jules Settings")
        return jules_settings.get_password("jules_api_key")

    return None

def _generate_ideas_for_repo(source_repo, api_key):
    """
    Given a source repository and an API key, this function calls the Jules API
    with a series of prompts and returns a consolidated list of structured ideas.
    """
    all_ideas = []
    prompts = _get_prompts()

    for item in prompts:
        session_id = _create_jules_session(api_key, source_repo, item["title"], item["prompt"])
        if not session_id:
            continue

        activities = _get_jules_activities(api_key, session_id)
        latest_response = _get_latest_agent_message(activities)

        if latest_response:
            ideas = _parse_ideas_from_response(latest_response)
            for idea in ideas:
                idea['type'] = "Bug" if "bug" in item["title"].lower() else "Feature"
            all_ideas.extend(ideas)

    return all_ideas

def _save_ideas_to_roadmap(roadmap_name, ideas):
    """Saves a list of generated ideas to a specified Roadmap document."""
    roadmap_doc = frappe.get_doc("Roadmap", roadmap_name)
    for idea in ideas:
        feature_doc = frappe.new_doc("Roadmap Feature")
        feature_doc.feature = idea.get("title")
        feature_doc.explanation = idea.get("explanation")
        feature_doc.status = "Ideas"
        feature_doc.is_ai_generated = 1
        feature_doc.type = idea.get("type", "Feature")
        roadmap_doc.append("features", feature_doc)

    roadmap_doc.save(ignore_permissions=True)
    frappe.db.commit()

def _get_prompts():
    """Returns a static list of prompts for idea generation."""
    return [
        {"title": "Suggest New Features", "prompt": 'Analyze the entire codebase... Respond in JSON format: {"ideas": [{"title": "...", "explanation": "..."}]}'},
        {"title": "Suggest Improvements", "prompt": 'Review the existing code... Respond in JSON format: {"ideas": [{"title": "...", "explanation": "..."}]}'},
        {"title": "Identify Potential Bugs", "prompt": 'Perform a static analysis... Respond in JSON format: {"ideas": [{"title": "...", "explanation": "..."}]}'}
    ]

def _parse_ideas_from_response(response_text):
    """Safely parses a JSON string and returns a list of ideas."""
    try:
        return json.loads(response_text).get("ideas", [])
    except (json.JSONDecodeError, AttributeError):
        frappe.log_error(f"Failed to parse JSON response from Jules: {response_text}", "Jules Idea Generation")
        return []

def _create_jules_session(api_key, source_repo, title, prompt):
    api_url = "https://jules.googleapis.com/v1alpha/sessions"
    headers = {"Content-Type": "application/json", "X-Goog-Api-Key": api_key}
    data = {"prompt": prompt, "sourceContext": {"source": source_repo, "githubRepoContext": {"startingBranch": "main"}}, "title": title, "requirePlanApproval": True}
    response = requests.post(api_url, json=data, headers=headers, timeout=30)
    response.raise_for_status()
    return response.json().get("name")

def _get_jules_activities(api_key, session_id):
    api_url = f"https://jules.googleapis.com/v1alpha/{session_id}/activities"
    headers = {"X-Goog-Api-Key": api_key}
    for _ in range(10):
        frappe.sleep(30)
        response = requests.get(api_url, headers=headers, timeout=15)
        response.raise_for_status()
        activities = response.json().get("activities", [])
        if len(activities) > 1:
            return activities
    return []

def _get_latest_agent_message(activities):
    return next((act.get("agentActivity", {}).get("message") for act in reversed(activities) if act.get("agentActivity")), None)

def jules_task_monitor():
    # Placeholder for existing function
    pass