# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import create_parcel_order, get_user_parcel_orders, get_user_parcel_order
import json

class TestParcelOrderAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_parcel_order@example.com",
            "first_name": "Test",
            "last_name": "Parcel",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")

        # Create a parcel order setting
        self.parcel_setting = frappe.get_doc({
            "doctype": "Parcel Order Setting",
            "title": "Standard"
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        # Clean up created documents
        frappe.db.delete("Parcel Order", {"user": self.test_user.name})
        self.parcel_setting.delete(ignore_permissions=True)
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_create_parcel_order(self):
        order_data = {
            "total_price": 100.0,
            "currency": "USD",
            "type": self.parcel_setting.name,
            "address_from": {"city": "City A"},
            "address_to": {"city": "City B"},
        }
        order = create_parcel_order(order_data=json.dumps(order_data))
        self.assertEqual(order.get("user"), self.test_user.name)
        self.assertEqual(order.get("total_price"), 100.0)

    def test_get_user_parcel_orders(self):
        # Create a parcel order first
        order_data = {"type": self.parcel_setting.name}
        create_parcel_order(order_data=json.dumps(order_data))

        orders = get_user_parcel_orders()
        self.assertTrue(isinstance(orders, list))
        self.assertEqual(len(orders), 1)
        self.assertEqual(orders[0].get("status"), "New")

    def test_get_user_parcel_order(self):
        # Create a parcel order first
        order_data = {"type": self.parcel_setting.name, "total_price": 123.45}
        created_order = create_parcel_order(order_data=json.dumps(order_data))

        order = get_user_parcel_order(name=created_order.get("name"))
        self.assertEqual(order.get("name"), created_order.get("name"))
        self.assertEqual(order.get("total_price"), 123.45)

    def test_get_other_user_parcel_order_permission(self):
        # Create another user and an order for them
        other_user = frappe.get_doc({
            "doctype": "User", "email": "other@example.com", "first_name": "Other"
        }).insert(ignore_permissions=True)

        # Switch to other user to create order
        frappe.set_user(other_user.name)
        order_data = {"type": self.parcel_setting.name}
        other_order = create_parcel_order(order_data=json.dumps(order_data))

        # Switch back to test_user
        frappe.set_user(self.test_user.name)

        # test_user should not be able to get other_user's order
        with self.assertRaises(frappe.PermissionError):
            get_user_parcel_order(name=other_order.get("name"))

        # Clean up other user
        frappe.set_user("Administrator")
        other_user.delete(ignore_permissions=True)

