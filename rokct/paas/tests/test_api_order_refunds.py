# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import create_order_refund, get_user_order_refunds

class TestOrderRefundsAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_refunds@example.com",
            "first_name": "Test",
            "last_name": "Refunds",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")

        # Create a test order
        self.order = frappe.get_doc({
            "doctype": "Order",
            "user": self.test_user.name,
            "status": "Delivered"
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        frappe.db.delete("Order Refund", {"order": self.order.name})
        self.order.delete(ignore_permissions=True)
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_create_and_get_order_refund(self):
        refund = create_order_refund(order=self.order.name, cause="Item was damaged")
        self.assertEqual(refund.get("order"), self.order.name)
        self.assertEqual(refund.get("cause"), "Item was damaged")
        self.assertEqual(refund.get("status"), "Pending")

        refunds = get_user_order_refunds()
        self.assertEqual(len(refunds), 1)
        self.assertEqual(refunds[0].get("order"), self.order.name)

    def test_permission_on_create_refund(self):
        # Create another user
        other_user = frappe.get_doc({
            "doctype": "User", "email": "other_refund@example.com", "first_name": "Other"
        }).insert(ignore_permissions=True)

        # Log in as other_user
        frappe.set_user(other_user.name)

        # other_user should not be able to create a refund for self.order
        with self.assertRaises(frappe.PermissionError):
            create_order_refund(order=self.order.name, cause="I want a refund")

        # Clean up
        frappe.set_user("Administrator")
        other_user.delete(ignore_permissions=True)

