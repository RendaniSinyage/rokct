# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import create_request_model, get_user_request_models
import json

class TestRequestModelAPI(FrappeTestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_request_model@example.com",
            "first_name": "Test",
            "last_name": "Request",
            "send_welcome_email": 0
        }).insert(ignore_permissions=True)
        self.test_user.add_roles("System Manager")

        # Create a test product to request changes for
        self.product = frappe.get_doc({
            "doctype": "Product",
            "product_name": "Test Product"
        }).insert(ignore_permissions=True)

        frappe.db.commit()

        # Log in as the test user
        frappe.set_user(self.test_user.name)

    def tearDown(self):
        # Log out
        frappe.set_user("Administrator")
        frappe.db.delete("Request Model", {"created_by_user": self.test_user.name})
        self.product.delete(ignore_permissions=True)
        self.test_user.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_create_and_get_request_models(self):
        request_data = {
            "new_field": "new_value"
        }
        request = create_request_model(
            model_type="Product",
            model_id=self.product.name,
            data=request_data
        )
        self.assertEqual(request.get("model_type"), "Product")
        self.assertEqual(request.get("model"), self.product.name)
        self.assertEqual(request.get("created_by_user"), self.test_user.name)

        requests = get_user_request_models()
        self.assertEqual(len(requests), 1)
        self.assertEqual(requests[0].get("model"), self.product.name)

