# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.paas.api import check_coupon

class TestCouponAPI(FrappeTestCase):
    def setUp(self):
        # Create a shop
        self.shop = frappe.get_doc({
            "doctype": "Shop",
            "shop_name": "TestShopAPICoupon",
            "owner": "Administrator"
        }).insert(ignore_permissions=True)

        # Create coupons
        self.valid_coupon = frappe.get_doc({
            "doctype": "Coupon",
            "code": "VALID10",
            "shop": self.shop.name,
            "type": "Percentage",
            "amount": 10
        }).insert(ignore_permissions=True)

        self.expired_coupon = frappe.get_doc({
            "doctype": "Coupon",
            "code": "EXPIRED",
            "shop": self.shop.name,
            "type": "Fixed",
            "amount": 5,
            "expired_at": "2020-01-01 00:00:00"
        }).insert(ignore_permissions=True)

        self.zero_quantity_coupon = frappe.get_doc({
            "doctype": "Coupon",
            "code": "ZEROQ",
            "shop": self.shop.name,
            "type": "Percentage",
            "amount": 20,
            "quantity": 0
        }).insert(ignore_permissions=True)
        frappe.db.commit()

    def tearDown(self):
        self.valid_coupon.delete(ignore_permissions=True)
        self.expired_coupon.delete(ignore_permissions=True)
        self.zero_quantity_coupon.delete(ignore_permissions=True)
        self.shop.delete(ignore_permissions=True)
        frappe.db.commit()

    def test_check_valid_coupon(self):
        result = check_coupon(coupon_code="VALID10", shop_id=self.shop.name)
        self.assertEqual(result.get("code"), "VALID10")
        self.assertEqual(result.get("amount"), 10)

    def test_check_invalid_coupon(self):
        result = check_coupon(coupon_code="INVALID", shop_id=self.shop.name)
        self.assertEqual(result.get("status"), "error")
        self.assertEqual(result.get("message"), "Invalid Coupon")

    def test_check_expired_coupon(self):
        result = check_coupon(coupon_code="EXPIRED", shop_id=self.shop.name)
        self.assertEqual(result.get("status"), "error")
        self.assertEqual(result.get("message"), "Coupon expired")

    def test_check_zero_quantity_coupon(self):
        result = check_coupon(coupon_code="ZEROQ", shop_id=self.shop.name)
        self.assertEqual(result.get("status"), "error")
        self.assertEqual(result.get("message"), "Coupon has been fully used")

    def test_missing_parameters(self):
        with self.assertRaises(frappe.exceptions.ValidationError):
            check_coupon(coupon_code="", shop_id=self.shop.name)
        with self.assertRaises(frappe.exceptions.ValidationError):
            check_coupon(coupon_code="VALID10", shop_id="")

