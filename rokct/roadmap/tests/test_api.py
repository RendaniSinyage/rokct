import unittest
from unittest.mock import patch, MagicMock
import sys
import json
import base64

# Pre-import mock of frappe to handle its complex structure
mock_frappe = MagicMock()

def passthrough_decorator(*args, **kwargs):
    def decorator(f):
        return f
    return decorator

mock_frappe.whitelist = passthrough_decorator
mock_frappe.PermissionError = PermissionError

def raise_exception(msg, exc=None):
    if exc:
        raise exc(msg)
    raise Exception(msg)

mock_frappe.throw = MagicMock(side_effect=raise_exception)

sys.modules['frappe'] = mock_frappe

# Now we can safely import the functions we want to test.
from rokct.roadmap.api import setup_github_workflow

API_MODULE_PATH = 'rokct.roadmap.api'

class TestRoadmapApi(unittest.TestCase):

    def setUp(self):
        # Reset all mocks before each test to ensure a clean state
        mock_frappe.reset_mock()
        mock_frappe.throw.side_effect = raise_exception
        mock_frappe.PermissionError = PermissionError

        # Patch external dependencies
        self.patcher_requests_put = patch(f'{API_MODULE_PATH}.requests.put')
        self.mock_requests_put = self.patcher_requests_put.start()
        self.patcher_requests_get = patch(f'{API_MODULE_PATH}.requests.get')
        self.mock_requests_get = self.patcher_requests_get.start()

    def tearDown(self):
        self.patcher_requests_put.stop()
        self.patcher_requests_get.stop()

    def _setup_workflow_mocks(self, config_values, repo_url="https://github.com/test-owner/test-repo"):
        """Helper function to set up common mocks for workflow tests."""
        mock_roadmap_doc = MagicMock()
        mock_roadmap_doc.source_repository = repo_url
        mock_frappe.get_doc.return_value = mock_roadmap_doc
        mock_frappe.conf.get.side_effect = lambda key, default=None: config_values.get(key, default)

    def _get_workflow_content_from_put_call(self):
        """Helper to decode the workflow content from the mock PUT call."""
        put_call_args = self.mock_requests_put.call_args
        put_data = json.loads(put_call_args[1]['data'])
        return base64.b64decode(put_data['content']).decode('utf-8')

    # --- Tests for setup_github_workflow ---
    def test_workflow_setup_for_tenant_url(self):
        """Test that the correct URL is generated for a tenant."""
        config = {
            "app_role": "tenant",
            "db_name": "bwi_tenant_rokct_ai",
            "tenant_site_scheme": "https",
            "github_personal_access_token": "test-pat"
        }
        self._setup_workflow_mocks(config)
        self.mock_requests_put.return_value.status_code = 201

        setup_github_workflow("Test-Roadmap")

        workflow_content = self._get_workflow_content_from_put_call()
        expected_url = "https://bwi.tenant.rokct.ai/api/method/rokct.roadmap.api.update_task_status_from_pr"
        self.assertIn(expected_url, workflow_content)

    def test_workflow_setup_for_control_panel_url(self):
        """Test that the correct URL is generated for the control panel."""
        config = {
            "app_role": "control_panel",
            "control_plane_url": "http://platform.rokct.ai",
            "github_personal_access_token": "test-pat"
        }
        self._setup_workflow_mocks(config)
        self.mock_requests_put.return_value.status_code = 201

        setup_github_workflow("Test-Roadmap")

        workflow_content = self._get_workflow_content_from_put_call()
        expected_url = "http://platform.rokct.ai/api/method/rokct.roadmap.api.update_task_status_from_pr"
        self.assertIn(expected_url, workflow_content)

    def test_workflow_setup_missing_pat(self):
        """Test that the setup fails if the GitHub PAT is not configured."""
        self._setup_workflow_mocks(config_values={"app_role": "tenant"}) # No PAT in config

        with self.assertRaises(Exception):
            setup_github_workflow("Test-Roadmap")
        mock_frappe.throw.assert_called_with("GitHub Personal Access Token is not configured in site_config.json.")

if __name__ == '__main__':
    unittest.main()