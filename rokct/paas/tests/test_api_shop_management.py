# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import get_user_shop, update_user_shop
import json

class TestShopManagementAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "shop_owner@example.com",
            "first_name": "Shop",
            "last_name": "Owner",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)

        # Create a test shop (Company) and link it to the user
        self.shop = frappe.get_doc({
            "doctype": "Company",
            "company_name": "My Awesome Shop",
            "user_id": self.test_user.name  # Assuming this custom field exists
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        self.shop.delete(ignore_permissions=True)
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_get_user_shop(self):
        shop = get_user_shop()
        self.assertIsNotNone(shop)
        self.assertEqual(shop.get("name"), self.shop.name)
        self.assertEqual(shop.get("company_name"), "My Awesome Shop")

    def test_update_user_shop(self):
        shop_data = {
            "title": "My Updated Shop",
            "phone": "1234567890",
            "open": 0
        }
        updated_shop = update_user_shop(shop_data=json.dumps(shop_data))
        self.assertEqual(updated_shop.get("company_name"), "My Updated Shop")
        self.assertEqual(updated_shop.get("phone"), "1234567890")
        self.assertEqual(updated_shop.get("open"), 0)

    def test_update_other_user_shop_permission(self):
        # Create another user and shop
        other_user = frappe.get_doc({
            "doctype": "User", "email": "other_owner@example.com", "first_name": "Other"
        }).insert(ignore_permissions=True)
        other_shop = frappe.get_doc({
            "doctype": "Company", "company_name": "Other Shop", "user_id": other_user.name
        }).insert(ignore_permissions=True)

        # Logged in as self.test_user, should not be able to update other_shop
        with self.assertRaises(frappe.PermissionError):
            update_user_shop(shop_data=json.dumps({"title": "Hacked Shop"}))

        # Clean up
        other_shop.delete(ignore_permissions=True)
        other_user.delete(ignore_permissions=True)

