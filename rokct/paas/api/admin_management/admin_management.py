import frappe
import json
from ..utils import _require_admin

@frappe.whitelist()
def get_all_shops(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shops on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Company",
        fields=["name", "company_name", "user_id"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def get_all_roles(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all roles on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Role",
        fields=["name", "role_name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_shop(shop_data):
    """
    Creates a new shop (for admins).
    """
    _require_admin()
    if isinstance(shop_data, str):
        shop_data = json.loads(shop_data)

    new_shop = frappe.get_doc({
        "doctype": "Company",
        **shop_data
    })
    new_shop.insert(ignore_permissions=True)
    return new_shop.as_dict()


@frappe.whitelist()
def update_shop(shop_name, shop_data):
    """
    Updates a shop (for admins).
    """
    _require_admin()
    if isinstance(shop_data, str):
        shop_data = json.loads(shop_data)

    shop = frappe.get_doc("Company", shop_name)
    shop.update(shop_data)
    shop.save(ignore_permissions=True)
    return shop.as_dict()


@frappe.whitelist()
def delete_shop(shop_name):
    """
    Deletes a shop (for admins).
    """
    _require_admin()
    frappe.delete_doc("Company", shop_name, ignore_permissions=True)
    return {"status": "success", "message": "Shop deleted successfully."}


@frappe.whitelist()
def get_all_users(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all users on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "User",
        fields=["name", "full_name", "email", "enabled"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )