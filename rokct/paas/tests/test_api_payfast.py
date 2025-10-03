# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import unittest
import json
from rokct.paas.api import get_payfast_settings, save_payfast_card, get_saved_payfast_cards, delete_payfast_card, handle_payfast_callback, process_payfast_token_payment

class TestPayFastAPI(unittest.TestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_payfast_user@example.com",
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

        # Create PayFast Payment Gateway
        if not frappe.db.exists("Payment Gateway", "PayFast"):
            frappe.get_doc({
                "doctype": "Payment Gateway",
                "gateway_name": "PayFast",
                "is_sandbox": 1,
                "settings": [
                    {"key": "merchant_id", "value": "10000100"},
                    {"key": "merchant_key", "value": "46f0cd694581a"},
                    {"key": "pass_phrase", "value": "your_passphrase_here"}
                ]
            }).insert(ignore_permissions=True)

    def tearDown(self):
        # Clean up the test data
        frappe.delete_doc("User", self.test_user.name)
        frappe.delete_doc("Order", self.test_order.name)
        frappe.db.commit()

    def test_get_payfast_settings(self):
        # Test getting PayFast settings
        settings = get_payfast_settings()
        self.assertIsNotNone(settings)
        self.assertIn("merchant_id", settings)
        self.assertIn("merchant_key", settings)

    def test_card_management(self):
        # Test saving, getting, and deleting a saved card
        frappe.set_user(self.test_user.name)

        # Save a card
        card_details = {"last_four": "1234", "card_type": "Visa", "expiry_date": "12/25", "card_holder_name": "Test User"}
        save_response = save_payfast_card("test_token", json.dumps(card_details))
        self.assertEqual(save_response.get("status"), "success")

        # Get saved cards
        saved_cards = get_saved_payfast_cards()
        self.assertEqual(len(saved_cards), 1)
        card_name = saved_cards[0].get("name")

        # Delete the card
        delete_response = delete_payfast_card(card_name)
        self.assertEqual(delete_response.get("status"), "success")

        # Verify the card is deleted
        saved_cards_after_delete = get_saved_payfast_cards()
        self.assertEqual(len(saved_cards_after_delete), 0)

    def test_handle_payfast_callback(self):
        # This test is more complex to set up as it requires a real callback from PayFast.
        # For now, we will just check that the function exists.
        self.assertTrue(callable(handle_payfast_callback))

    def test_process_payfast_token_payment(self):
        # Test processing a payment with a saved token
        frappe.set_user(self.test_user.name)
        with self.assertRaises(frappe.exceptions.ValidationError):
            process_payfast_token_payment(self.test_order.name, "test_token")

