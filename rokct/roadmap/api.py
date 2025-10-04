import frappe
import json
import requests
from rokct.roadmap.tasks import _get_api_key, _create_jules_session

@frappe.whitelist(allow_guest=True)
def update_task_status_from_pr():
    """
    Receives a secure call from our custom GitHub Action to update a task's status.
    """
    # ... (existing implementation) ...
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
    Checks if the GitHub workflow file exists in the repository. If not,
    it delegates the task of creating the file to Jules via a new session.
    """
    # 1. Get roadmap and GitHub details
    roadmap_doc = frappe.get_doc("Roadmap", roadmap_name)
    repo_url = roadmap_doc.source_repository
    if not repo_url:
        frappe.throw("Roadmap does not have a source repository defined.")

    github_pat = frappe.conf.get("github_personal_access_token")
    if not github_pat:
        frappe.throw("GitHub Personal Access Token is not configured in site_config.json.")

    try:
        parts = repo_url.strip('/').split('/')
        owner = parts[-2]
        repo = parts[-1].replace('.git', '')
    except IndexError:
        frappe.throw("Invalid GitHub repository URL format. Expected: https://github.com/owner/repo")

    # 2. Check if the workflow file already exists
    workflow_path = ".github/workflows/rokct_pr_merged.yml"
    api_url = f"https://api.github.com/repos/{owner}/{repo}/contents/{workflow_path}"
    headers = {"Authorization": f"token {github_pat}", "Accept": "application/vnd.github.v3+json"}

    try:
        response = requests.get(api_url, headers=headers)
        if response.status_code == 200:
            return {"status": "exists", "message": "The GitHub workflow file already exists in your repository."}
        elif response.status_code != 404:
            frappe.throw(f"Failed to check for workflow file. GitHub API responded with status {response.status_code}: {response.text}")
    except requests.exceptions.RequestException as e:
        frappe.throw(f"Could not connect to GitHub API: {e}")

    # 3. If file does not exist (404), delegate to Jules
    jules_api_key = _get_api_key()
    if not jules_api_key:
        frappe.throw("Jules API key is not configured.")

    # 4. Construct the prompt for Jules
    if frappe.conf.get("app_role") == "control_panel":
        site_url = frappe.conf.get("control_plane_url")
    else:
        db_name = frappe.conf.get("db_name")
        scheme = frappe.conf.get("tenant_site_scheme", "https")
        hostname = db_name.replace('_', '.')
        site_url = f"{scheme}://{hostname}"

    api_endpoint_url = f"{site_url}/api/method/rokct.roadmap.api.update_task_status_from_pr"

    workflow_content = f"""name: 'Update ROKCT Task on PR Merged'
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
          rokct-action-token: ${{{{ secrets.ROKCT_ACTION_TOKEN }}}}"""

    prompt = f"""Please create a new file in the repository.
File path: `{workflow_path}`
File content:
```yaml
{workflow_content}
```
Then, create a pull request for this change with the title "feat: Add ROKCT PR-to-task workflow" and a suitable description.
Do not ask for a plan. Do not write any other code. Just create the file and the pull request."""

    # 5. Create the Jules session
    session_id = _create_jules_session(jules_api_key, repo_url, "Setup ROKCT Workflow", prompt)

    if session_id:
        return {
            "status": "session_created",
            "session_id": session_id,
            "message": "Jules has been tasked with creating a pull request for the workflow file. Please check your repository shortly."
        }
    else:
        frappe.throw("Failed to create a Jules session.")