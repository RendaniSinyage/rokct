import unittest
from unittest.mock import patch, MagicMock
import sys

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
from rokct.roadmap.api import update_task_status_from_pr, setup_github_workflow

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

    # --- Tests for setup_github_workflow ---
    def test_workflow_setup_success(self):
        """Test successful creation of the GitHub workflow file."""
        # --- Test-specific mock setup ---
        mock_roadmap_doc = MagicMock()
        mock_roadmap_doc.source_repository = "https://github.com/test-owner/test-repo"
        mock_frappe.get_doc.return_value = mock_roadmap_doc
        mock_frappe.conf.get.return_value = "test-pat"
        self.mock_requests_get.return_value.status_code = 404 # File does not exist
        self.mock_requests_put.return_value.status_code = 201 # File created

        response = setup_github_workflow("Test-Roadmap")

        self.mock_requests_put.assert_called_once()
        self.assertEqual(response['status'], 'success')

    def test_workflow_setup_update_success(self):
        """Test successful update of an existing GitHub workflow file."""
        mock_roadmap_doc = MagicMock()
        mock_roadmap_doc.source_repository = "https://github.com/test-owner/test-repo"
        mock_frappe.get_doc.return_value = mock_roadmap_doc
        mock_frappe.conf.get.return_value = "test-pat"
        self.mock_requests_get.return_value.status_code = 200
        self.mock_requests_get.return_value.json.return_value = {'sha': 'test-sha'}
        self.mock_requests_put.return_value.status_code = 200 # File updated

        response = setup_github_workflow("Test-Roadmap")

        self.mock_requests_put.assert_called_once()
        self.assertIn('sha', self.mock_requests_put.call_args[1]['data'])
        self.assertEqual(response['status'], 'success')

    def test_workflow_setup_missing_repo_url(self):
        """Test that the setup fails if the roadmap has no source repository."""
        mock_roadmap_doc = MagicMock()
        mock_roadmap_doc.source_repository = None
        mock_frappe.get_doc.return_value = mock_roadmap_doc

        with self.assertRaises(Exception):
            setup_github_workflow("Test-Roadmap")
        mock_frappe.throw.assert_called_with("Roadmap does not have a source repository defined.")

    def test_workflow_setup_missing_pat(self):
        """Test that the setup fails if the GitHub PAT is not configured."""
        mock_roadmap_doc = MagicMock()
        mock_roadmap_doc.source_repository = "https://github.com/test-owner/test-repo"
        mock_frappe.get_doc.return_value = mock_roadmap_doc
        mock_frappe.conf.get.return_value = None

        with self.assertRaises(Exception):
            setup_github_workflow("Test-Roadmap")
        mock_frappe.throw.assert_called_with("GitHub Personal Access Token is not configured in site_config.json.")

    def test_workflow_setup_github_api_failure(self):
        """Test that the setup fails gracefully if the GitHub API call fails."""
        mock_roadmap_doc = MagicMock()
        mock_roadmap_doc.source_repository = "https://github.com/test-owner/test-repo"
        mock_frappe.get_doc.return_value = mock_roadmap_doc
        mock_frappe.conf.get.return_value = "test-pat"
        self.mock_requests_put.return_value.status_code = 500
        self.mock_requests_put.return_value.text = "Internal Server Error"

        with self.assertRaises(Exception):
            setup_github_workflow("Test-Roadmap")
        mock_frappe.throw.assert_called_with("Failed to create GitHub workflow file. Status: 500, Response: Internal Server Error")

if __name__ == '__main__':
    unittest.main()