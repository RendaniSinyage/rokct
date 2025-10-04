import frappe
from ..utils import _get_seller_shop

@frappe.whitelist()
def get_seller_payouts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of payouts for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    payouts = frappe.get_list(
        "Seller Payout",
        filters={"shop": shop},
        fields=["name", "amount", "payout_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payout_date desc"
    )
    return payouts