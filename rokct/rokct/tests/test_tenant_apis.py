# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch
from rokct.rokct.tenant.api import get_subscription_details
from frappe.utils import generate_hash


class TestTenantAPIs(FrappeTestCase):
    def setUp(self):
        frappe.conf.app_role = "tenant"
        frappe.conf.control_plane_url = "http://test-control-plane.com"
        self.test_secret = generate_hash(length=32)
        frappe.conf.api_secret = self.test_secret

    def tearDown(self):
        frappe.db.rollback()
        for key in ["app_role", "control_plane_url", "api_secret"]:
            if hasattr(frappe.conf, key):
                delattr(frappe.conf, key)

    @patch("rokct.rokct.tenant.api.frappe.make_post_request")
    def test_get_subscription_details_proxy(self, mock_make_post_request):
        # Arrange
        mock_response = {
            "status": "Active",
            "plan": "Test Plan",
            "modules": ["Core", "Accounts"],
            "subscription_cache_duration": 600,
        }
        mock_make_post_request.return_value = {"message": mock_response}

        # Act
        response = get_subscription_details()

        # Assert
        mock_make_post_request.assert_called_once()

        # Check the URL
        expected_url = "http://test-control-plane.com/api/method/rokct.control_panel.api.get_subscription_status"
        self.assertEqual(mock_make_post_request.call_args.args[0], expected_url)

        # Check the headers for the correct secret and header key
        expected_headers = {"X-Rokct-Secret": self.test_secret}
        self.assertEqual(
            mock_make_post_request.call_args.kwargs["headers"], expected_headers
        )

        # Check that the response is passed through correctly
        self.assertEqual(response, mock_response)

