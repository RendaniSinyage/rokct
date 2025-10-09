# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import unittest
import json
from rokct.paas.api import create_order, list_orders, get_order_details, update_order_status, add_order_review, cancel_order

class TestOrderAPI(unittest.TestCase):
    def setUp(self):
        # Create a test user
        self.test_user = frappe.get_doc({
            "doctype": "User",
            "email": "test_order_user@example.com",
            "first_name": "Test",
            "last_name": "User"
        }).insert(ignore_permissions=True)

        # Create a test shop
        self.test_shop = frappe.get_doc({
            "doctype": "Seller",
            "seller_name": "Test Shop",
            "tax": 10
        }).insert(ignore_permissions=True)

        # Create PaaS Settings
        if not frappe.db.exists("DocType", "PaaS Settings"):
            frappe.get_doc({
                "doctype": "DocType",
                "name": "PaaS Settings",
                "module": "paas",
                "custom": 1,
                "issingle": 1,
                "fields": [
                    {
                        "fieldname": "service_fee",
                        "fieldtype": "Currency",
                        "label": "Service Fee"
                    }
                ]
            }).insert(ignore_permissions=True)

        paas_settings = frappe.get_doc("PaaS Settings")
        paas_settings.service_fee = 10
        paas_settings.save(ignore_permissions=True)

        # Create a test product
        self.test_product = frappe.get_doc({
            "doctype": "Product",
            "product_name": "Test Product",
            "price": 100
        }).insert(ignore_permissions=True)

        # Ensure USD currency exists
        if not frappe.db.exists("Currency", "USD"):
            frappe.get_doc({
                "doctype": "Currency",
                "currency_name": "USD",
                "symbol": "$",
                "enabled": 1
            }).insert(ignore_permissions=True)
        self.test_currency = "USD"

    def tearDown(self):
        # Clean up the test data
        frappe.delete_doc("User", self.test_user.name)
        frappe.delete_doc("Seller", self.test_shop.name)
        frappe.delete_doc("Product", self.test_product.name)
        frappe.db.commit()

    def test_create_order_and_calculation(self):
        # Test creating a new order and that the calculation is correct
        order_data = {
            "user": self.test_user.name,
            "shop": self.test_shop.name,
            "delivery_type": "Delivery",
            "currency": self.test_currency,
            "rate": 1,
            "order_items": [
                {
                    "product": self.test_product.name,
                    "quantity": 2,
                    "price": 100
                }
            ]
        }
        order_dict = create_order(json.dumps(order_data))
        self.assertIsNotNone(order_dict)

        order = frappe.get_doc("Order", order_dict.get("name"))
        # 2 * 100 = 200 (subtotal)
        # + 10% tax = 220
        # + 10 service fee = 230
        self.assertEqual(order.total_price, 230)

    def test_list_orders(self):
        # Test listing orders for the current user
        frappe.set_user(self.test_user.name)
        orders = list_orders()
        self.assertIsNotNone(orders)
        self.assertIsInstance(orders, list)

    def test_get_order_details(self):
        # Test getting the details of a specific order
        order = frappe.get_doc({
            "doctype": "Order",
            "user": self.test_user.name,
            "shop": self.test_shop.name,
        }).insert(ignore_permissions=True)
        frappe.set_user(self.test_user.name)
        order_details = get_order_details(order.name)
        self.assertIsNotNone(order_details)
        self.assertEqual(order_details.get("name"), order.name)

    def test_update_order_status(self):
        # Test updating the status of an order
        order = frappe.get_doc({
            "doctype": "Order",
            "user": self.test_user.name,
            "shop": self.test_shop.name,
        }).insert(ignore_permissions=True)
        frappe.set_user(self.test_user.name)
        updated_order = update_order_status(order.name, "Accepted")
        self.assertIsNotNone(updated_order)
        self.assertEqual(updated_order.get("status"), "Accepted")

    def test_add_order_review(self):
        # Test adding a review to an order
        order = frappe.get_doc({
            "doctype": "Order",
            "user": self.test_user.name,
            "shop": self.test_shop.name,
            "status": "Delivered"
        }).insert(ignore_permissions=True)

        frappe.set_user(self.test_user.name)
        review = add_order_review(order.name, 5, "Great service!")
        self.assertIsNotNone(review)
        self.assertEqual(review.get("rating"), 5)
        self.assertEqual(review.get("comment"), "Great service!")

    def test_cancel_order(self):
        # Test cancelling an order
        order = frappe.get_doc({
            "doctype": "Order",
            "user": self.test_user.name,
            "shop": self.test_shop.name,
            "status": "New",
            "order_items": [
                {
                    "product": self.test_product.name,
                    "quantity": 1,
                    "price": 100
                }
            ]
        }).insert(ignore_permissions=True)
        frappe.set_user(self.test_user.name)
        cancelled_order = cancel_order(order.name)
        self.assertIsNotNone(cancelled_order)
        self.assertEqual(cancelled_order.get("status"), "Cancelled")

