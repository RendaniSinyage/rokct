import frappe
from ..seller.utils import _get_seller_shop

@frappe.whitelist()
def get_seller_statistics():
    """
    Retrieves sales and order statistics for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    total_sales = frappe.db.sql("""
        SELECT SUM(grand_total)
        FROM `tabOrder`
        WHERE shop = %(shop)s AND status = 'Delivered'
    """, {"shop": shop})[0][0] or 0

    total_orders = frappe.db.count("Order", {"shop": shop})

    top_selling_products = frappe.db.sql("""
        SELECT oi.product, i.item_name, SUM(oi.quantity) as total_quantity
        FROM `tabOrder Item` as oi
        JOIN `tabOrder` as o ON o.name = oi.parent
        JOIN `tabItem` as i ON i.name = oi.product
        WHERE o.shop = %(shop)s
        GROUP BY oi.product, i.item_name
        ORDER BY total_quantity DESC
        LIMIT 10
    """, {"shop": shop}, as_dict=True)

    return {
        "total_sales": total_sales,
        "total_orders": total_orders,
        "top_selling_products": top_selling_products
    }


@frappe.whitelist()
def get_seller_sales_report(from_date: str, to_date: str):
    """
    Retrieves a sales report for the current seller's shop within a date range.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    sales_report = frappe.get_all(
        "Order",
        filters={
            "shop": shop,
            "creation": ["between", [from_date, to_date]]
        },
        fields=["name", "user", "grand_total", "status", "creation"],
        order_by="creation desc"
    )
    return sales_report