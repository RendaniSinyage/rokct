# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import unittest
from unittest.mock import patch, Mock
from rokct.paas.api import initiate_paystack_payment, handle_paystack_callback

class TestPayStackAPI(unittest.TestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_paystack_user@example.com",
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

        # Create PayStack Payment Gateway
        if not frappe.db.exists("Payment Gateway", "PayStack"):
            frappe.get_doc({
                "doctype": "Payment Gateway",
                "gateway_name": "PayStack",
                "is_sandbox": 1,
                "settings": [
                    {"key": "paystack_sk", "value": "test_secret_key"}
                ]
            }).insert(ignore_permissions=True)

    def tearDown(self):
        frappe.delete_doc("User", self.test_user.name)
        frappe.delete_doc("Order", self.test_order.name)
        frappe.db.commit()

    @patch('rokct.paas.api.requests.post')
    def test_initiate_paystack_payment(self, mock_post):
        # Mock the response from PayStack API
        mock_response = Mock()
        mock_response.json.return_value = {
            "status": True,
            "data": {
                "authorization_url": "https://checkout.paystack.com/test_url",
                "reference": "test_reference"
            }
        }
        mock_post.return_value = mock_response

        response = initiate_paystack_payment(self.test_order.name)

        self.assertIn("redirect_url", response)
        self.assertIn("test_url", response["redirect_url"])

        # Verify a transaction was created
        self.assertTrue(frappe.db.exists("Transaction", {"transaction_id": "test_reference"}))

    @patch('rokct.paas.api.requests.get')
    def test_handle_paystack_callback(self, mock_get):
        # Create a dummy transaction to be updated by the callback
        frappe.get_doc({
            "doctype": "Transaction",
            "reference_doctype": "Order",
            "reference_name": self.test_order.name,
            "transaction_id": "test_reference_callback",
            "status": "Pending"
        }).insert(ignore_permissions=True)

        # Mock the response from PayStack API
        mock_response = Mock()
        mock_response.json.return_value = {"data": {"status": "success"}}
        mock_get.return_value = mock_response

        # Simulate a callback from PayStack
        with patch('frappe.form_dict', {"reference": "test_reference_callback"}):
            handle_paystack_callback()

        # Check if the transaction and order status were updated
        updated_transaction = frappe.get_doc("Transaction", {"transaction_id": "test_reference_callback"})
        self.assertEqual(updated_transaction.status, "Completed")

        updated_order = frappe.get_doc("Order", self.test_order.name)
        self.assertEqual(updated_order.status, "Paid")

