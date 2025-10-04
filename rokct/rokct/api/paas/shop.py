# Copyright (c) 2025, ROKCT and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document

@frappe.whitelist()
def create_shop(shop_data):
    """
    Creates a new Shop document.
    Only users with 'System Manager' or 'Seller' roles can create a shop.
    """
    if "System Manager" not in frappe.get_roles() and "Seller" not in frappe.get_roles():
        frappe.throw("You are not authorized to create a shop.", frappe.PermissionError)

    if not isinstance(shop_data, dict):
        frappe.throw("shop_data must be a dictionary.", frappe.ValidationError)

    # Set the current user as the owner if not specified
    if 'user' not in shop_data:
        shop_data['user'] = frappe.session.user

    try:
        shop = frappe.get_doc({
            "doctype": "Shop",
            **shop_data
        })
        shop.insert(ignore_permissions=True)
        frappe.db.commit()
        return shop.as_dict()
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Shop Creation Failed")
        frappe.throw(f"An error occurred while creating the shop: {e}")