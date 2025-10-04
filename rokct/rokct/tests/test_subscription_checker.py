# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.rokct.utils.subscription_checker import check_subscription_feature

class TestSubscriptionChecker(FrappeTestCase):

    @patch('rokct.rokct.utils.subscription_checker.get_subscription_details')
    def test_active_subscription_with_feature(self, mock_get_subscription_details):
        # Arrange
        mock_get_subscription_details.return_value = {
            "status": "Active",
            "modules": ["phone_verification", "another_feature"]
        }

        @check_subscription_feature("phone_verification")
        def dummy_function():
            return "success"

        # Act
        result = dummy_function()

        # Assert
        self.assertEqual(result, "success")

    @patch('rokct.rokct.utils.subscription_checker.get_subscription_details')
    def test_inactive_subscription(self, mock_get_subscription_details):
        # Arrange
        mock_get_subscription_details.return_value = {
            "status": "Expired",
            "modules": ["phone_verification"]
        }

        @check_subscription_feature("phone_verification")
        def dummy_function():
            pass

        # Act & Assert
        with self.assertRaises(frappe.PermissionError) as cm:
            dummy_function()
        self.assertEqual(str(cm.exception), "Your subscription is not active.")

    @patch('rokct.rokct.utils.subscription_checker.get_subscription_details')
    def test_active_subscription_without_feature(self, mock_get_subscription_details):
        # Arrange
        mock_get_subscription_details.return_value = {
            "status": "Active",
            "modules": ["another_feature"]
        }

        @check_subscription_feature("phone_verification")
        def dummy_function():
            pass

        # Act & Assert
        with self.assertRaises(frappe.PermissionError) as cm:
            dummy_function()
        self.assertEqual(str(cm.exception), "Your plan does not include the 'phone_verification' feature.")

    @patch('rokct.rokct.utils.subscription_checker.get_subscription_details')
    def test_no_subscription_details(self, mock_get_subscription_details):
        # Arrange
        mock_get_subscription_details.return_value = None

        @check_subscription_feature("phone_verification")
        def dummy_function():
            pass

        # Act & Assert
        with self.assertRaises(frappe.PermissionError) as cm:
            dummy_function()
        self.assertEqual(str(cm.exception), "Could not retrieve subscription details.")

    @patch('rokct.rokct.utils.subscription_checker.get_subscription_details')
    @patch('rokct.rokct.utils.subscription_checker.frappe.cache')
    def test_caching_logic(self, mock_cache, mock_get_subscription_details):
        # Arrange
        mock_cache_instance = MagicMock()
        mock_cache.return_value = mock_cache_instance
        mock_cache_instance.get_value.return_value = None # First call misses the cache

        mock_get_subscription_details.return_value = {
            "status": "Active",
            "modules": ["test_feature"],
            "subscription_cache_duration": 3600
        }

        @check_subscription_feature("test_feature")
        def dummy_function():
            return "success"

        # Act: Call the function twice
        dummy_function()

        # Simulate cache hit on second call
        mock_cache_instance.get_value.return_value = {
            "status": "Active",
            "modules": ["test_feature"]
        }
        dummy_function()

        # Assert
        self.assertEqual(mock_get_subscription_details.call_count, 1)
        self.assertEqual(mock_cache_instance.get_value.call_count, 2)
        self.assertEqual(mock_cache_instance.set_value.call_count, 1)

        # Check that the expiration was set correctly
        args, kwargs = mock_cache_instance.set_value.call_args
        self.assertEqual(kwargs["expires_in_sec"], 3600)

