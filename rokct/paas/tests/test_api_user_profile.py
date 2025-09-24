# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import get_user_profile, update_user_profile
import json

class TestUserProfileAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_user_profile@example.com",
            "first_name": "Test",
            "last_name": "User",
            "phone": "1234567890",
            "birth_date": "1990-01-01",
            "gender": "Male",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")
        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_get_user_profile(self):
        profile = get_user_profile()
        self.assertEqual(profile.get("first_name"), "Test")
        self.assertEqual(profile.get("last_name"), "User")
        self.assertEqual(profile.get("email"), "test_user_profile@example.com")
        self.assertEqual(profile.get("phone"), "1234567890")
        self.assertEqual(profile.get("birth_date"), "1990-01-01")
        self.assertEqual(profile.get("gender"), "Male")

    def test_update_user_profile(self):
        profile_data = {
            "first_name": "Updated",
            "last_name": "Name",
            "phone": "0987654321",
            "birth_date": "1991-02-02",
            "gender": "Female"
        }
        response = update_user_profile(profile_data=json.dumps(profile_data))
        self.assertEqual(response.get("status"), "success")

        # Verify the changes
        updated_profile = get_user_profile()
        self.assertEqual(updated_profile.get("first_name"), "Updated")
        self.assertEqual(updated_profile.get("last_name"), "Name")
        self.assertEqual(updated_profile.get("phone"), "0987654321")
        self.assertEqual(updated_profile.get("birth_date"), "1991-02-02")
        self.assertEqual(updated_profile.get("gender"), "Female")

    def test_update_user_profile_unauthorized_fields(self):
        profile_data = {
            "email": "new_email@example.com",
            "roles": ["Administrator"]
        }
        update_user_profile(profile_data=json.dumps(profile_data))

        # Verify that the unauthorized fields were not changed
        updated_profile = get_user_profile()
        self.assertEqual(updated_profile.get("email"), "test_user_profile@example.com")
        self.assertTrue("Administrator" not in self.test_user.get_roles())

