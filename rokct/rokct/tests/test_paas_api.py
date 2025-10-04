# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.paas.api import check_phone, send_phone_verification_code, verify_phone_code

class TestPhoneVerificationAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user_phone = "+19876543210"
        if not frappe.db.exists("User", "test_phone_user@example.com"):
            self.test_user = frappe.get_doc({
                "doctype": "User",
                "email": "test_phone_user@example.com",
                "first_name": "Test",
                "last_name": "User",
                "phone": self.test_user_phone,
            }).insert(ignore_permissions=True)
        else:
            self.test_user = frappe.get_doc("User", "test_phone_user@example.com")

        # Reset phone_verified_at for each test to ensure independence
        self.test_user.phone_verified_at = None
        self.test_user.save(ignore_permissions=True)


    def tearDown(self):
        frappe.db.rollback()

    def test_check_phone_exists(self):
        response = check_phone(phone=self.test_user_phone)
        self.assertEqual(response["status"], "error")
        self.assertEqual(response["message"], "Phone number already exists.")

    def test_check_phone_not_exists(self):
        response = check_phone(phone="+10123456789")
        self.assertEqual(response["status"], "success")
        self.assertEqual(response["message"], "Phone number is available.")

    def test_check_phone_missing_param(self):
        with self.assertRaises(frappe.ValidationError):
            check_phone(phone="")

    @patch("rokct.paas.api.frappe.send_sms")
    @patch("rokct.paas.api.frappe.cache")
    def test_send_verification_code(self, mock_cache, mock_send_sms):
        mock_cache_instance = MagicMock()
        mock_cache.return_value = mock_cache_instance

        phone_number = "+11223344556"
        response = send_phone_verification_code(phone=phone_number)

        self.assertEqual(response["status"], "success")

        # Check that cache was called correctly
        args, kwargs = mock_cache_instance.set_value.call_args
        self.assertEqual(args[0], f"phone_otp:{phone_number}")
        self.assertTrue(args[1].isdigit())
        self.assertEqual(len(args[1]), 6)
        self.assertEqual(kwargs["expires_in_sec"], 600)

        # Check that SMS was sent correctly
        otp = args[1]
        mock_send_sms.assert_called_once_with(
            receivers=[phone_number],
            message=f"Your verification code is: {otp}"
        )

    @patch("rokct.paas.api.frappe.cache")
    def test_verify_code_correct(self, mock_cache):
        mock_cache_instance = MagicMock()
        mock_cache.return_value = mock_cache_instance

        phone_number = self.test_user_phone
        correct_otp = "123456"

        mock_cache_instance.get_value.return_value = correct_otp

        response = verify_phone_code(phone=phone_number, otp=correct_otp)

        self.assertEqual(response["status"], "success")
        self.assertEqual(response["message"], "Phone number verified successfully.")

        # Verify user's phone_verified_at is set
        self.test_user.reload()
        self.assertIsNotNone(self.test_user.phone_verified_at)

        # Verify cache deletion
        mock_cache_instance.delete_value.assert_called_once_with(f"phone_otp:{phone_number}")

    @patch("rokct.paas.api.frappe.cache")
    def test_verify_code_incorrect(self, mock_cache):
        mock_cache_instance = MagicMock()
        mock_cache.return_value = mock_cache_instance

        phone_number = self.test_user_phone
        correct_otp = "123456"
        incorrect_otp = "654321"

        mock_cache_instance.get_value.return_value = correct_otp

        response = verify_phone_code(phone=phone_number, otp=incorrect_otp)

        self.assertEqual(response["status"], "error")
        self.assertEqual(response["message"], "Invalid verification code.")

        # Verify user's phone_verified_at is NOT set
        self.test_user.reload()
        self.assertIsNone(self.test_user.phone_verified_at)

        # Verify cache was not deleted
        mock_cache_instance.delete_value.assert_not_called()

    @patch("rokct.paas.api.frappe.cache")
    def test_verify_code_expired(self, mock_cache):
        mock_cache_instance = MagicMock()
        mock_cache.return_value = mock_cache_instance
        mock_cache_instance.get_value.return_value = None

        response = verify_phone_code(phone=self.test_user_phone, otp="123456")

        self.assertEqual(response["status"], "error")
        self.assertEqual(response["message"], "OTP expired or was not sent. Please request a new one.")

    def test_api_status(self):
        # Act
        from rokct.paas.api import api_status
        response = api_status()

        # Assert
        self.assertEqual(response["status"], "ok")
        self.assertIn("version", response)
        self.assertIn("user", response)

    @patch("frappe.core.doctype.user.user.reset_password")
    def test_forgot_password(self, mock_reset_password):
        # Arrange
        from rokct.paas.api import forgot_password

        # Act
        response = forgot_password(user=self.test_user.email)

        # Assert
        self.assertEqual(response["status"], "success")
        mock_reset_password.assert_called_once_with(user=self.test_user.email)

    def test_get_languages(self):
        # Arrange
        from rokct.paas.api import get_languages
        # Ensure there is at least one enabled and one disabled language
        if not frappe.db.exists("Language", "en"):
            frappe.get_doc({"doctype": "Language", "language_code": "en", "language_name": "English", "enabled": 1}).insert()
        if not frappe.db.exists("Language", "tlh"):
             frappe.get_doc({"doctype": "Language", "language_code": "tlh", "language_name": "Klingon", "enabled": 0}).insert()

        # Act
        response = get_languages()

        # Assert
        self.assertIsInstance(response, list)
        self.assertTrue(len(response) > 0)

        # Create a list of names from the response for easier checking
        response_names = [lang['name'] for lang in response]
        self.assertIn("en", response_names)
        self.assertNotIn("tlh", response_names)

    def test_get_currencies(self):
        # Arrange
        from rokct.paas.api import get_currencies
        # Ensure there is at least one enabled and one disabled currency
        if not frappe.db.exists("Currency", "USD"):
            frappe.get_doc({"doctype": "Currency", "currency_name": "USD", "symbol": "$", "enabled": 1}).insert()
        if not frappe.db.exists("Currency", "KLG"):
             frappe.get_doc({"doctype": "Currency", "currency_name": "Klingon Darsek", "symbol": "KLG", "enabled": 0}).insert()

        # Act
        response = get_currencies()

        # Assert
        self.assertIsInstance(response, list)
        self.assertTrue(len(response) > 0)

        # Create a list of names from the response for easier checking
        response_names = [c['name'] for c in response]
        self.assertIn("USD", response_names)
        self.assertNotIn("KLG", response_names)

    @patch("rokct.paas.api.frappe.sendmail")
    def test_register_user(self, mock_sendmail):
        # Arrange
        from rokct.paas.api import register_user
        new_user_email = "new_user@example.com"

        # Act
        response = register_user(
            email=new_user_email,
            password="password123",
            first_name="New",
            last_name="User"
        )

        # Assert
        self.assertEqual(response["status"], "success")
        self.assertTrue(frappe.db.exists("User", new_user_email))
        new_user = frappe.get_doc("User", new_user_email)
        self.assertIsNotNone(new_user.email_verification_token)
        mock_sendmail.assert_called_once()

