# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import get_user_membership, get_user_membership_history

class TestMembershipAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_membership@example.com",
            "first_name": "Test",
            "last_name": "Membership",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")

        # Create a membership plan
        self.membership_plan = frappe.get_doc({
            "doctype": "Membership",
            "title": "Gold Plan",
            "price": 100.0,
            "duration": 1,
            "duration_unit": "Month"
        }).insert(ignore_permissions=True)

        # Create a user membership
        self.user_membership = frappe.get_doc({
            "doctype": "User Membership",
            "user": self.test_user.name,
            "membership": self.membership_plan.name,
            "start_date": frappe.utils.nowdate(),
            "end_date": frappe.utils.add_months(frappe.utils.nowdate(), 1)
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        self.user_membership.delete(ignore_permissions=True)
        self.membership_plan.delete(ignore_permissions=True)
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_get_user_membership(self):
        membership = get_user_membership()
        self.assertIsNotNone(membership)
        self.assertEqual(membership.get("membership"), self.membership_plan.name)

    def test_get_user_membership_history(self):
        history = get_user_membership_history()
        self.assertTrue(isinstance(history, list))
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0].get("membership"), self.membership_plan.name)

    def test_get_user_membership_no_active_membership(self):
        self.user_membership.is_active = 0
        self.user_membership.save(ignore_permissions=True)
        frappe.db.commit()

        membership = get_user_membership()
        self.assertIsNone(membership)

