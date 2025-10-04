import frappe
import json
import requests
import base64

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

        return {"status": "success", "message": f"Task {feature_doc_name} marked as Done."}
    else:
        return {"status": "not_found", "message": "No matching task found."}

@frappe.whitelist()
def setup_github_workflow(roadmap_name):
    """
    Creates the .github/workflows/rokct_pr_merged.yml file in the repository
    associated with the given roadmap.
    """
    # 1. Get roadmap details
    roadmap_doc = frappe.get_doc("Roadmap", roadmap_name)
    repo_url = roadmap_doc.source_repository
    if not repo_url:
        frappe.throw("Roadmap does not have a source repository defined.")

    # 2. Get GitHub token from a secure setting
    github_pat = frappe.conf.get("github_personal_access_token")
    if not github_pat:
        frappe.throw("GitHub Personal Access Token is not configured in site_config.json.")

    # 3. Parse owner and repo from URL
    try:
        parts = repo_url.strip('/').split('/')
        owner = parts[-2]
        repo = parts[-1].replace('.git', '')
    except IndexError:
        frappe.throw("Invalid GitHub repository URL format. Expected: https://github.com/owner/repo")

    # 4. Define workflow file content
    # Construct the site URL from the database name for robustness, as suggested.
    db_name = frappe.conf.get("db_name")
    site_hostname = db_name.replace('_', '.')
    api_endpoint_url = f"https://{site_hostname}/api/method/rokct.roadmap.api.update_task_status_from_pr"

    workflow_content = f"""
name: 'Update ROKCT Task on PR Merged'
on:
  pull_request:
    types: [closed]

jobs:
  update_rokct_task:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - name: 'Jules PR Closer'
        uses: rokct/jules-pr-closer-action@v1
        with:
          repo-token: ${{{{ secrets.GITHUB_TOKEN }}}}
          rokct-api-endpoint: '{api_endpoint_url}'
          rokct-action-token: ${{{{ secrets.ROKCT_ACTION_TOKEN }}}}
"""
    # 5. Use GitHub API to create/update the file
    api_url = f"https://api.github.com/repos/{owner}/{repo}/contents/.github/workflows/rokct_pr_merged.yml"
    headers = {
        "Authorization": f"token {github_pat}",
        "Accept": "application/vnd.github.v3+json"
    }

    encoded_content = base64.b64encode(workflow_content.encode('utf-8')).decode('utf-8')

    data = {
        "message": "feat: Add ROKCT PR-to-task workflow",
        "content": encoded_content,
        "committer": {
            "name": "ROKCT Automation",
            "email": "automation@rokct.ai"
        }
    }

    # Check if file exists to get its SHA (required for update)
    try:
        get_response = requests.get(api_url, headers=headers)
        if get_response.status_code == 200:
            data['sha'] = get_response.json()['sha']
    except requests.exceptions.RequestException as e:
        frappe.log_error(f"Could not check for existing workflow file: {e}")

    put_response = requests.put(api_url, headers=headers, data=json.dumps(data))

    if put_response.status_code in [200, 201]:
        return {"status": "success", "message": "GitHub workflow file created/updated successfully."}
    else:
        frappe.throw(f"Failed to create GitHub workflow file. Status: {put_response.status_code}, Response: {put_response.text}")