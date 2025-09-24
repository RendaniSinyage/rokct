import frappe
import unittest
from unittest.mock import patch, Mock
from rokct.paas.api import initiate_paypal_payment, handle_paypal_callback

class TestPayPalAPI(unittest.TestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_paypal_user@example.com",
            "first_name": "Test",
            "last_name": "User"
        }).insert(ignore_permissions=True)

        # Create a test order
        self.test_order = frappe.get_doc({
            "doctype": "Order",
            "user": self.test_user.name,
            "total_price": 100,
            "currency": "USD",
        }).insert(ignore_permissions=True)

        # Create PayPal Payment Gateway
        if not frappe.db.exists("Payment Gateway", "PayPal"):
            frappe.get_doc({
                "doctype": "Payment Gateway",
                "gateway_name": "PayPal",
                "is_sandbox": 1,
                "settings": [
                    {"key": "paypal_sandbox_client_id", "value": "test_client_id"},
                    {"key": "paypal_sandbox_client_secret", "value": "test_secret"},
                    {"key": "paypal_mode", "value": "sandbox"}
                ]
            }).insert(ignore_permissions=True)

    def tearDown(self):
        frappe.delete_doc("User", self.test_user.name)
        frappe.delete_doc("Order", self.test_order.name)
        frappe.db.commit()

    @patch('rokct.paas.api.requests.post')
    def test_initiate_paypal_payment(self, mock_post):
        # Mock the responses from PayPal API
        mock_auth_response = Mock()
        mock_auth_response.json.return_value = {"access_token": "test_access_token"}

        mock_order_response = Mock()
        mock_order_response.json.return_value = {
            "id": "test_paypal_order_id",
            "links": [{"rel": "approve", "href": "https://www.sandbox.paypal.com/checkoutnow?token=test_paypal_order_id"}]
        }

        mock_post.side_effect = [mock_auth_response, mock_order_response]

        response = initiate_paypal_payment(self.test_order.name)

        self.assertIn("redirect_url", response)
        self.assertIn("test_paypal_order_id", response["redirect_url"])

        # Verify a transaction was created
        self.assertTrue(frappe.db.exists("Transaction", {"transaction_id": "test_paypal_order_id"}))

    @patch('rokct.paas.api.requests.get')
    @patch('rokct.paas.api.requests.post')
    def test_handle_paypal_callback(self, mock_post, mock_get):
        # Create a dummy transaction to be updated by the callback
        frappe.get_doc({
            "doctype": "Transaction",
            "reference_doctype": "Order",
            "reference_name": self.test_order.name,
            "transaction_id": "test_paypal_order_id_callback",
            "status": "Pending"
        }).insert(ignore_permissions=True)

        # Mock the responses from PayPal API
        mock_auth_response = Mock()
        mock_auth_response.json.return_value = {"access_token": "test_access_token"}
        mock_post.return_value = mock_auth_response

        mock_order_response = Mock()
        mock_order_response.json.return_value = {"status": "COMPLETED"}
        mock_get.return_value = mock_order_response

        # Simulate a callback from PayPal
        with patch('frappe.form_dict', {"token": "test_paypal_order_id_callback"}):
            handle_paypal_callback()

        # Check if the transaction and order status were updated
        updated_transaction = frappe.get_doc("Transaction", {"transaction_id": "test_paypal_order_id_callback"})
        self.assertEqual(updated_transaction.status, "Completed")

        updated_order = frappe.get_doc("Order", self.test_order.name)
        self.assertEqual(updated_order.status, "Paid")

