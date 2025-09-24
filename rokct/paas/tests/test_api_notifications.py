# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import get_user_notifications

class TestNotificationsAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_notifications@example.com",
            "first_name": "Test",
            "last_name": "Notifications",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")

        # Create a notification log for the user
        frappe.get_doc({
            "doctype": "Notification Log",
            "subject": "Test Notification",
            "for_user": self.test_user.name,
            "document_type": "User",
            "document_name": self.test_user.name
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        frappe.db.delete("Notification Log", {"for_user": self.test_user.name})
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_get_user_notifications(self):
        notifications = get_user_notifications()
        self.assertTrue(isinstance(notifications, list))
        self.assertEqual(len(notifications), 1)
        self.assertEqual(notifications[0].get("subject"), "Test Notification")

