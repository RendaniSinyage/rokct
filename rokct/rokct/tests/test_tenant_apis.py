import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.tenant.api import get_subscription_details

class TestTenantAPIs(FrappeTestCase):
    def setUp(self):
        frappe.conf.app_role = "tenant"
        frappe.conf.control_plane_url = "http://test-control-plane.com"
        frappe.conf.api_secret = "test_secret"

    def tearDown(self):
        frappe.db.rollback()
        if hasattr(frappe.conf, "app_role"):
            del frappe.conf.app_role
        if hasattr(frappe.conf, "control_plane_url"):
            del frappe.conf.control_plane_url
        if hasattr(frappe.conf, "api_secret"):
            del frappe.conf.api_secret

    @patch("rokct.tenant.api.frappe.make_post_request")
    def test_get_subscription_details_proxy(self, mock_make_post_request):
        # Arrange
        mock_response = {
            "status": "Active",
            "plan": "Test Plan",
            "modules": ["Core", "Accounts"]
        }
        mock_make_post_request.return_value = {"message": mock_response}

        # Act
        response = get_subscription_details()

        # Assert
        mock_make_post_request.assert_called_once()

        # Check the URL
        expected_url = "http://test-control-plane.com/api/method/rokct.control_panel.api.get_subscription_status"
        self.assertEqual(mock_make_post_request.call_args.args[0], expected_url)

        # Check the headers
        expected_headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer test_secret"
        }
        self.assertEqual(mock_make_post_request.call_args.kwargs["headers"], expected_headers)

        # Check that the response is passed through correctly
        self.assertEqual(response, mock_response)

