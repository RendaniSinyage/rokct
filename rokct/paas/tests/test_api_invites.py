# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import create_invite, get_user_invites, update_invite_status

class TestInvitesAPI(FrappeTestCase):
    def setUp(self):
        # Create test users
        self.inviting_user = frappe.get_doc({
            "doctype": "User", "email": "inviter@example.com", "first_name": "Inviter"
        }).insert(ignore_permissions=True)
        self.invited_user = frappe.get_doc({
            "doctype": "User", "email": "invited@example.com", "first_name": "Invited"
        }).insert(ignore_permissions=True)

        # Create a test shop (Company)
        self.shop = frappe.get_doc({
            "doctype": "Company", "company_name": "Test Invite Shop"
        }).insert(ignore_permissions=True)

        frappe.db.commit()

    def tearDown(self):
        frappe.db.delete("Invitation")
        self.shop.delete(ignore_permissions=True)
        self.inviting_user.delete(ignore_permissions=True)
        self.invited_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_create_and_get_invites(self):
        # Log in as the inviting user to create the invite
        frappe.set_user(self.inviting_user.name)
        invite = create_invite(shop=self.shop.name, user=self.invited_user.name, role="Collaborator")
        self.assertEqual(invite.get("shop"), self.shop.name)
        self.assertEqual(invite.get("user"), self.invited_user.name)
        self.assertEqual(invite.get("status"), "New")

        # Log in as the invited user to see the invite
        frappe.set_user(self.invited_user.name)
        invites = get_user_invites()
        self.assertEqual(len(invites), 1)
        self.assertEqual(invites[0].get("shop"), self.shop.name)

    def test_update_invite_status(self):
        # Create an invite first
        frappe.set_user(self.inviting_user.name)
        invite = create_invite(shop=self.shop.name, user=self.invited_user.name, role="Collaborator")

        # Log in as the invited user to update the status
        frappe.set_user(self.invited_user.name)
        updated_invite = update_invite_status(name=invite.get("name"), status="Accepted")
        self.assertEqual(updated_invite.get("status"), "Accepted")

        # Test invalid status
        with self.assertRaises(frappe.exceptions.ValidationError):
            update_invite_status(name=invite.get("name"), status="InvalidStatus")

    def test_permission_on_invite_update(self):
        # Create an invite
        frappe.set_user(self.inviting_user.name)
        invite = create_invite(shop=self.shop.name, user=self.invited_user.name, role="Collaborator")

        # The inviting user should not be able to update the status
        with self.assertRaises(frappe.PermissionError):
            update_invite_status(name=invite.get("name"), status="Accepted")

