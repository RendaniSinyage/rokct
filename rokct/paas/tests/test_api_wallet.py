# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import get_user_wallet, get_wallet_history
import uuid

class TestWalletAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_wallet@example.com",
            "first_name": "Test",
            "last_name": "Wallet",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")

        # Create a wallet for the user
        self.wallet = frappe.get_doc({
            "doctype": "Wallet",
            "uuid": str(uuid.uuid4()),
            "user": self.test_user.name,
            "currency": "USD",
            "price": 100.0
        }).insert(ignore_permissions=True)

        # Create wallet history
        frappe.get_doc({
            "doctype": "Wallet History",
            "uuid": str(uuid.uuid4()),
            "wallet": self.wallet.name,
            "type": "Topup",
            "price": 100.0,
            "status": "Paid"
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        frappe.db.delete("Wallet History", {"wallet": self.wallet.name})
        self.wallet.delete(ignore_permissions=True)
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_get_user_wallet(self):
        wallet = get_user_wallet()
        self.assertEqual(wallet.get("user"), self.test_user.name)
        self.assertEqual(wallet.get("price"), 100.0)

    def test_get_wallet_history_pagination(self):
        # Create a second history record
        frappe.get_doc({
            "doctype": "Wallet History",
            "uuid": str(uuid.uuid4()),
            "wallet": self.wallet.name,
            "type": "Withdraw",
            "price": 50.0,
            "status": "Paid"
        }).insert(ignore_permissions=True)
        frappe.db.commit()

        # Get the first page with a limit of 1
        history = get_wallet_history(limit_page_length=1)
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0].get("type"), "Withdraw") # It's ordered by creation desc

        # Get the second page
        history = get_wallet_history(limit_start=1, limit_page_length=1)
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0].get("type"), "Topup")

