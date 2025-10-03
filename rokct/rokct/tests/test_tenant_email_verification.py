# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.rokct.tenant.api import verify_my_email, resend_verification_email

class TestTenantEmailVerification(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user_email = "test_email_verification_user@example.com"
        if not frappe.db.exists("User", self.test_user_email):
            self.test_user = frappe.get_doc({
                "doctype": "User",
                "email": self.test_user_email,
                "first_name": "Email Test",
                "last_name": "User",
            }).insert(ignore_permissions=True)
        else:
            self.test_user = frappe.get_doc("User", self.test_user_email)

        # Reset fields for each test to ensure independence
        self.test_user.email_verified_at = None
        self.test_user.email_verification_token = None
        self.test_user.save(ignore_permissions=True)

    def tearDown(self):
        frappe.db.rollback()

    def test_verify_email_with_valid_token(self):
        # Arrange
        token = frappe.generate_hash(length=48)
        self.test_user.email_verification_token = token
        self.test_user.save(ignore_permissions=True)
        frappe.db.commit()

        # Act
        with patch('rokct.rokct.tenant.api._notify_control_panel_of_verification'):
            verify_my_email(token=token)

        # Assert
        self.test_user.reload()
        self.assertIsNotNone(self.test_user.email_verified_at)
        self.assertIsNone(self.test_user.email_verification_token)

    def test_verify_email_with_invalid_token(self):
        # Act
        verify_my_email(token="invalidtoken")

        # Assert
        self.test_user.reload()
        self.assertIsNone(self.test_user.email_verified_at)

    @patch("rokct.rokct.tenant.api.frappe.sendmail")
    def test_resend_verification_email(self, mock_sendmail):
        # Arrange
        frappe.set_user(self.test_user.name) # Set current user for security check

        # Act
        response = resend_verification_email(email=self.test_user_email)

        # Assert
        self.assertEqual(response["status"], "success")
        self.test_user.reload()
        self.assertIsNotNone(self.test_user.email_verification_token)

        mock_sendmail.assert_called_once()
        kwargs = mock_sendmail.call_args.kwargs
        self.assertEqual(kwargs['recipients'], [self.test_user_email])
        self.assertEqual(kwargs['template'], "Resend Verification")
        self.assertIn('verification_url', kwargs['args'])

    def test_resend_for_already_verified_email(self):
        # Arrange
        self.test_user.email_verified_at = frappe.utils.now_datetime()
        self.test_user.save(ignore_permissions=True)
        frappe.db.commit()
        frappe.set_user(self.test_user.name)

        # Act
        response = resend_verification_email(email=self.test_user_email)

        # Assert
        self.assertEqual(response["status"], "success")
        self.assertEqual(response["message"], "Email is already verified.")

    def test_resend_permission_denied(self):
        # Arrange
        # Create another user to test permission
        other_user_email = "other_user@example.com"
        if not frappe.db.exists("User", other_user_email):
            frappe.get_doc({
                "doctype": "User", "email": other_user_email, "first_name": "Other", "last_name": "User"
            }).insert(ignore_permissions=True)

        frappe.set_user(self.test_user.name) # Logged in as test_user

        # Act and Assert
        with self.assertRaises(frappe.PermissionError):
            resend_verification_email(email=other_user_email)

        frappe.set_user("Administrator") # Clean up

