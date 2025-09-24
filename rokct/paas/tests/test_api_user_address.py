# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import add_user_address, get_user_addresses, get_user_address, update_user_address, delete_user_address
import json

class TestUserAddressAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_address@example.com",
            "first_name": "Test",
            "last_name": "Address",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")
        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        # Clean up created documents
        frappe.db.delete("User Address", {"user": self.test_user.name})
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_add_and_get_user_address(self):
        address_data = {
            "title": "Home",
            "address": {"city": "Testville"},
            "location": {"lat": 1, "lng": 2}
        }
        added_address = add_user_address(address_data=json.dumps(address_data))
        self.assertEqual(added_address.get("title"), "Home")
        self.assertEqual(added_address.get("user"), self.test_user.name)

        # Test get single address
        retrieved_address = get_user_address(name=added_address.get("name"))
        self.assertEqual(retrieved_address.get("title"), "Home")

        # Test get all addresses
        addresses = get_user_addresses()
        self.assertEqual(len(addresses), 1)
        self.assertEqual(addresses[0].get("title"), "Home")

    def test_update_user_address(self):
        address_data = {"title": "Work"}
        added_address = add_user_address(address_data=json.dumps({"title": "Initial"}))

        update_data = {"title": "Updated Work"}
        updated_address = update_user_address(name=added_address.get("name"), address_data=json.dumps(update_data))
        self.assertEqual(updated_address.get("title"), "Updated Work")

    def test_delete_user_address(self):
        added_address = add_user_address(address_data=json.dumps({"title": "To be deleted"}))

        response = delete_user_address(name=added_address.get("name"))
        self.assertEqual(response.get("status"), "success")

        addresses = get_user_addresses()
        self.assertEqual(len(addresses), 0)

    def test_permission_on_user_address(self):
        # Create another user and an address for them
        other_user = frappe.get_doc({
            "doctype": "User", "email": "other_addr@example.com", "first_name": "Other"
        }).insert(ignore_permissions=True)

        # Switch to other user to create order
        frappe.set_user(other_user.name)
        other_address = add_user_address(address_data=json.dumps({"title": "Other's Home"}))

        # Switch back to test_user
        frappe.set_user(self.test_user.name)

        # test_user should not be able to get, update, or delete other_user's address
        with self.assertRaises(frappe.PermissionError):
            get_user_address(name=other_address.get("name"))

        with self.assertRaises(frappe.PermissionError):
            update_user_address(name=other_address.get("name"), address_data=json.dumps({"title": "Hacked"}))

        with self.assertRaises(frappe.PermissionError):
            delete_user_address(name=other_address.get("name"))

        # Clean up other user
        frappe.set_user("Administrator")
        other_user.delete(ignore_permissions=True)

