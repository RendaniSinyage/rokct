import frappe
from ..seller.utils import _get_seller_shop

@frappe.whitelist()
def get_seller_transactions(limit_start=0, limit_page_length=20):
    """
    Retrieves a list of transactions for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all(
        "Order",
        filters={"shop": shop},
        pluck="name"
    )

    if not orders:
        return []

    transactions = frappe.get_all(
        "Transaction",
        filters={"reference_name": ["in", orders]},
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "debit", "credit", "currency"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return transactions


@frappe.whitelist()
def get_seller_shop_payments(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of shop payments for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all(
        "Order",
        filters={"shop": shop},
        pluck="name"
    )

    if not orders:
        return []

    payments = frappe.get_all(
        "Transaction",
        filters={
            "reference_name": ["in", orders],
            "credit": [">", 0]
        },
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "credit", "currency"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return payments

@frappe.whitelist()
def get_seller_payment_to_partners(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of payments to partners for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    payouts = frappe.get_list(
        "Payout",
        filters={"shop": shop},
        fields=["name", "deliveryman", "amount", "payment_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payment_date desc"
    )
    return payouts

@frappe.whitelist()
def get_seller_payment_to_partners(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of payments to partners for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    payouts = frappe.get_list(
        "Payout",
        filters={"shop": shop},
        fields=["name", "deliveryman", "amount", "payment_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payment_date desc"
    )
    return payouts