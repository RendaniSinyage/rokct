import frappe
from ..utils import _get_seller_shop

@frappe.whitelist()
def get_seller_bonuses(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of bonuses for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    bonuses = frappe.get_list(
        "Shop Bonus",
        filters={"shop": shop},
        fields=["name", "amount", "bonus_date", "reason"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="bonus_date desc"
    )
    return bonuses