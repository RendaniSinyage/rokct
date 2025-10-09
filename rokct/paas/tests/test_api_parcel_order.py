# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api.parcel.parcel import create_parcel_order, get_parcel_orders, update_parcel_status
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

        # Create a delivery point
        self.delivery_point = frappe.get_doc({
            "doctype": "Delivery Point",
            "name": "Test Delivery Point",
            "address": "123 Test Street"
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
        self.delivery_point.delete(ignore_permissions=True)
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

    def test_create_parcel_order_with_delivery_point(self):
        order_data = {
            "destination_type": "delivery_point",
            "delivery_point_id": self.delivery_point.name,
            "items": [{"item_code": "Test Item", "quantity": 1}]
        }
        order = create_parcel_order(order_data=json.dumps(order_data))
        self.assertEqual(order.get("delivery_point"), self.delivery_point.name)
        self.assertEqual(len(order.get("items")), 1)

    def test_get_parcel_orders(self):
        # Create a parcel order first
        order_data = {"type": self.parcel_setting.name}
        create_parcel_order(order_data=json.dumps(order_data))

        orders = get_parcel_orders()
        self.assertTrue(isinstance(orders, list))
        self.assertEqual(len(orders), 1)
        self.assertEqual(orders[0].get("status"), "New")

    def test_update_parcel_status(self):
        # Create a parcel order first
        order_data = {"type": self.parcel_setting.name}
        created_order = create_parcel_order(order_data=json.dumps(order_data))

        # Update the status
        updated_order = update_parcel_status(parcel_order_id=created_order.get("name"), status="Processing")
        self.assertEqual(updated_order.get("status"), "Processing")