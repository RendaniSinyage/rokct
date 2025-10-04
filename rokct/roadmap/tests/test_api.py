import unittest
from unittest.mock import patch, MagicMock
import sys

# We must patch 'frappe' before it's imported by the module we're testing.
mock_frappe = MagicMock()

# This is the key to solving the decorator problem. We make the mock decorator
# simply return the function it's decorating, so the original function logic is preserved.
def passthrough_decorator(*args, **kwargs):
    def decorator(f):
        return f
    return decorator

mock_frappe.whitelist = passthrough_decorator

# Mock the exception class
mock_frappe.PermissionError = PermissionError

# Mock the 'throw' function to actually raise an exception
def raise_exception(msg, exc=None):
    if exc:
        raise exc(msg)
    raise Exception(msg)

mock_frappe.throw = MagicMock(side_effect=raise_exception)

sys.modules['frappe'] = mock_frappe

# Now we can safely import the function we want to test.
from rokct.roadmap.api import update_task_status_from_pr

class TestRoadmapApi(unittest.TestCase):

    def setUp(self):
        # Reset the mock for each test to ensure isolation
        mock_frappe.reset_mock()
        mock_frappe.throw.side_effect = raise_exception # Re-apply side effect after reset
        mock_frappe.PermissionError = PermissionError

        # Set up a mock for the request data
        mock_frappe.request.data = '{"session_id": "test-session-123"}'
        mock_frappe.request.headers = {
            'X-ROKCT-ACTION-TOKEN': 'correct-secret-token'
        }
        mock_frappe.conf.get.return_value = 'correct-secret-token'

    def test_successful_status_update(self):
        """Test that the task status is updated to 'Done' on a valid request."""
        mock_feature_doc = MagicMock()
        mock_frappe.get_doc.return_value = mock_feature_doc
        mock_frappe.db.get_value.return_value = 'ROADMAP-FEATURE-001'

        response = update_task_status_from_pr()

        mock_frappe.db.get_value.assert_called_with("Roadmap Feature", {"jules_session_id": "test-session-123"})
        mock_frappe.get_doc.assert_called_with("Roadmap Feature", 'ROADMAP-FEATURE-001')
        mock_feature_doc.db_set.assert_called_with('status', 'Done')
        mock_frappe.db.commit.assert_called_once()
        self.assertEqual(response['status'], 'success')

    def test_authentication_failure(self):
        """Test that the request is rejected if the auth token is invalid."""
        mock_frappe.request.headers = {'X-ROKCT-ACTION-TOKEN': 'wrong-secret-token'}

        with self.assertRaises(PermissionError):
            update_task_status_from_pr()
        mock_frappe.throw.assert_called_with("Authentication failed.", mock_frappe.PermissionError)

    def test_missing_session_id(self):
        """Test that the request is rejected if the session_id is not provided."""
        mock_frappe.request.data = '{}' # Empty JSON

        with self.assertRaises(Exception):
             update_task_status_from_pr()
        mock_frappe.throw.assert_called_with("session_id not provided.")

    def test_task_not_found(self):
        """Test the case where no matching Roadmap Feature is found."""
        mock_frappe.db.get_value.return_value = None # Simulate no document found

        response = update_task_status_from_pr()

        mock_frappe.get_doc.assert_not_called()
        self.assertEqual(response['status'], 'not_found')

if __name__ == '__main__':
    unittest.main()