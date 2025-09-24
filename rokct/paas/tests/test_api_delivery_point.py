# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import get_delivery_points, get_delivery_point

class TestDeliveryPointAPI(FrappeTestCase):
    def setUp(self):
        # Create a test delivery point
        self.delivery_point = frappe.get_doc({
            "doctype": "Delivery Point",
            "name": "Test Delivery Point",
            "active": 1,
            "price": 10.0,
            "address": '{"city": "Test City", "street": "Test Street"}',
            "location": '{"latitude": 12.34, "longitude": 56.78}',
        }).insert(ignore_permissions=True)
        frappe.db.commit()

    def tearDown(self):
        self.delivery_point.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_get_delivery_points(self):
        # Unset user to test allow_guest=True
        frappe.set_user("Guest")
        points = get_delivery_points()
        self.assertTrue(isinstance(points, list))
        self.assertTrue(len(points) > 0)
        self.assertEqual(points[0].get("name"), "Test Delivery Point")
        # Set user back to Administrator
        frappe.set_user("Administrator")


    def test_get_delivery_point(self):
        # Unset user to test allow_guest=True
        frappe.set_user("Guest")
        point = get_delivery_point(name="Test Delivery Point")
        self.assertEqual(point.get("name"), "Test Delivery Point")
        self.assertEqual(point.get("price"), 10.0)
        # Set user back to Administrator
        frappe.set_user("Administrator")

    def test_get_inactive_delivery_point(self):
        self.delivery_point.active = 0
        self.delivery_point.save(ignore_permissions=True)
        frappe.db.commit()

        points = get_delivery_points()
        self.assertEqual(len(points), 0)

