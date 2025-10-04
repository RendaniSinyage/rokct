import frappe
from ..seller.utils import _get_seller_shop

@frappe.whitelist()
def get_seller_delivery_man_delivery_zones(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of delivery zones for the deliverymen of the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    deliverymen = frappe.db.sql_list("""
        SELECT DISTINCT deliveryman FROM `tabOrder` WHERE shop = %(shop)s AND deliveryman IS NOT NULL
    """, {"shop": shop})

    if not deliverymen:
        return []

    delivery_zones = frappe.get_list(
        "Deliveryman Delivery Zone",
        filters={"deliveryman": ["in", deliverymen]},
        fields=["name", "deliveryman", "delivery_zone"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )
    return delivery_zones

@frappe.whitelist()
def adjust_seller_inventory(item_code: str, warehouse: str, new_qty: int):
    """
    Adjusts the inventory for a specific item in a warehouse for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    item = frappe.get_doc("Item", item_code)
    if item.shop != shop:
        frappe.throw("You are not authorized to adjust inventory for this item.", frappe.PermissionError)

    # Get current quantity
    current_qty = frappe.db.get_value("Bin", {"item_code": item_code, "warehouse": warehouse}, "actual_qty") or 0

    # Create a stock reconciliation entry
    stock_entry = frappe.get_doc({
        "doctype": "Stock Entry",
        "purpose": "Stock Reconciliation",
        "company": shop,
        "items": [{
            "item_code": item_code,
            "warehouse": warehouse,
            "qty": new_qty,
            "basic_rate": item.standard_rate,
            "t_warehouse": warehouse,
            "s_warehouse": warehouse,
            "diff_qty": new_qty - current_qty
        }]
    })
    stock_entry.submit()

    return {"status": "success", "message": f"Inventory for {item_code} adjusted to {new_qty}."}