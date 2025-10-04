# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import unittest
import json
from rokct.paas.api import create_order

class TestCouponUsage(unittest.TestCase):
    def setUp(self):
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_coupon_user@example.com",
            "first_name": "Test",
            "last_name": "User"
        }).insert(ignore_permissions=True)

        self.test_shop = frappe.get_doc({
            "doctype": "Company",
            "company_name": "Test Shop for Coupon Usage",
            "abbr": "TSCU",
            "default_currency": "USD"
        }).insert(ignore_permissions=True)

        self.test_product = frappe.get_doc({
            "doctype": "Item",
            "item_name": "Test Product for Coupon",
            "item_code": "TPC",
            "item_group": "Products",
            "is_stock_item": 0
        }).insert(ignore_permissions=True)

        self.test_coupon = frappe.get_doc({
            "doctype": "Coupon",
            "coupon_name": "Test Coupon",
            "code": "TEST10",
            "type": "Percentage",
            "discount_percentage": 10,
            "shop": self.test_shop.name
        }).insert(ignore_permissions=True)

        if not frappe.db.exists("Currency", "USD"):
            frappe.get_doc({
                "doctype": "Currency",
                "currency_name": "USD",
                "symbol": "$",
                "enabled": 1
            }).insert(ignore_permissions=True)
        self.test_currency = "USD"
        frappe.db.commit()

    def tearDown(self):
        frappe.delete_doc("User", self.test_user.name, ignore_permissions=True)
        frappe.delete_doc("Company", self.test_shop.name, ignore_permissions=True)
        frappe.delete_doc("Item", self.test_product.name, ignore_permissions=True)
        frappe.delete_doc("Coupon", self.test_coupon.name, ignore_permissions=True)
        frappe.db.commit()

    def test_create_order_with_coupon_records_usage(self):
        frappe.set_user(self.test_user.name)
        order_data = {
            "user": self.test_user.name,
            "shop": self.test_shop.name,
            "delivery_type": "Delivery",
            "currency": self.test_currency,
            "rate": 1,
            "order_items": [
                {
                    "product": self.test_product.name,
                    "quantity": 1,
                    "price": 100
                }
            ],
            "coupon_code": self.test_coupon.code
        }

        order_dict = create_order(json.dumps(order_data))
        self.assertIsNotNone(order_dict)
        order_name = order_dict.get("name")

        # Check if Coupon Usage was created
        coupon_usage_exists = frappe.db.exists("Coupon Usage", {
            "user": self.test_user.name,
            "coupon": self.test_coupon.name,
            "order": order_name
        })
        self.assertTrue(coupon_usage_exists, "Coupon Usage document was not created.")

