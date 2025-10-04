import frappe
from ..seller.utils import _get_seller_shop

@frappe.whitelist()
def get_seller_request_models(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of request models for the current seller.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your request models.", frappe.AuthenticationError)

    request_models = frappe.get_list(
        "Request Model",
        filters={"created_by_user": user},
        fields=["name", "model_type", "model", "status", "created_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return request_models

@frappe.whitelist()
def get_seller_customer_addresses(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of customer addresses for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    customer_ids = frappe.db.sql_list("""
        SELECT DISTINCT user FROM `tabOrder` WHERE shop = %(shop)s
    """, {"shop": shop})

    if not customer_ids:
        return []

    addresses = frappe.get_all(
        "User Address",
        filters={"user": ["in", customer_ids]},
        fields=["name", "user", "title", "address", "location", "active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )
    return addresses