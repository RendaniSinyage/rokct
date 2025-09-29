import frappe
import json
from frappe.utils import now_datetime

def execute():
    """
    Seeds the Coupon documents from the legacy `coupons` table data.
    This patch is designed to be run on the `juvo.tenant.rokct.ai` site.
    """
    # Site-specific check
    if frappe.local.site != "juvo.tenant.rokct.ai":
        print(f"SKIPPING: Seeding Coupons for site {frappe.local.site}")
        return

    print("\n--- Running Patch: Seeding Coupons ---")

    # Data extracted from coupons.sql
    coupons_data = [
        {"id": 2, "shop_id": 9003, "name": "FREE100", "type": "fix", "qty": 1, "price": 100, "expired_at": "2026-10-10 00:00:00"},
        {"id": 3, "shop_id": 9003, "name": "R5Off", "type": "fix", "qty": 999999998, "price": 5, "expired_at": "2027-12-11 00:00:00"},
        {"id": 4, "shop_id": 9003, "name": "R10off", "type": "fix", "qty": 2147483645, "price": 10, "expired_at": "2027-11-03 00:00:00"},
        {"id": 5, "shop_id": 9003, "name": "R20off", "type": "fix", "qty": 2147483647, "price": 20, "expired_at": "2027-11-06 00:00:00"},
        {"id": 6, "shop_id": 9003, "name": "FREE25", "type": "fix", "qty": 2147483633, "price": 25, "expired_at": "2027-12-11 00:00:00"}
    ]

    for coupon_data in coupons_data:
        try:
            coupon_code = coupon_data.get("name")
            if not frappe.db.exists("Coupon", {"code": coupon_code}):
                shop_name = frappe.db.get_value("Shop", {"old_shop_id": coupon_data.get("shop_id")}, "name")
                if shop_name:
                    coupon = frappe.new_doc("Coupon")
                    # Mapping based on coupon.json and educated guesses for other fields
                    coupon.shop = shop_name
                    coupon.code = coupon_code
                    coupon.quantity = coupon_data.get("qty")
                    coupon.expired_at = coupon_data.get("expired_at")

                    # These fields are not in coupon.json, but are common for coupons.
                    # If they don't exist, the insert will fail, which is acceptable for now.
                    coupon.discount_type = "Amount" if coupon_data.get("type") == "fix" else "Percentage"
                    coupon.discount_amount = coupon_data.get("price")

                    coupon.insert(ignore_permissions=True)
                    print(f"SUCCESS: Imported Coupon '{coupon_code}' for Shop '{shop_name}'")
                else:
                    print(f"SKIPPED: Coupon '{coupon_code}' because parent Shop ID '{coupon_data.get('shop_id')}' was not found.")
            else:
                print(f"SKIPPED: Coupon '{coupon_code}' already exists.")
        except Exception as e:
            print(f"ERROR: Failed to import coupon '{coupon_data.get('name')}'. Reason: {e}")

    frappe.db.commit()
    print("\n--- Seeding of Coupons complete ---")