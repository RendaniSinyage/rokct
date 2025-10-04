import frappe
import json

@frappe.whitelist(allow_guest=True)
def update_task_status_from_pr():
    """
    Receives a secure call from our custom GitHub Action to update a task's status.
    """
    # 1. Authenticate the request
    auth_token = frappe.request.headers.get('X-ROKCT-ACTION-TOKEN')
    expected_token = frappe.conf.get("github_action_secret")
    if not auth_token or auth_token != expected_token:
        frappe.throw("Authentication failed.", frappe.PermissionError)

    # 2. Get the session ID from the request body
    data = json.loads(frappe.request.data)
    session_id = data.get("session_id")
    if not session_id:
        frappe.throw("session_id not provided.")

    # 3. Find and update the Roadmap Feature
    feature_doc_name = frappe.db.get_value("Roadmap Feature", {"jules_session_id": session_id})
    if feature_doc_name:
        feature_doc = frappe.get_doc("Roadmap Feature", feature_doc_name)
        feature_doc.db_set('status', 'Done')
        frappe.db.commit()

        # As discussed, we prepare for the future delete API call
        # delete_jules_session(session_id)

        return {"status": "success", "message": f"Task {feature_doc_name} marked as Done."}
    else:
        return {"status": "not_found", "message": "No matching task found."}