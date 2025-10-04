import frappe

@frappe.whitelist()
def get_cook_orders(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of orders assigned to the current cook.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.", frappe.AuthenticationError)

    orders = frappe.get_list(
        "Order",
        filters={"cook": user},
        fields=["name", "shop", "total_price", "status", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_cook_order_report(from_date: str, to_date: str):
    """
    Retrieves a report of orders for the current cook within a date range.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your order report.", frappe.AuthenticationError)

    orders = frappe.get_all(
        "Order",
        filters={
            "cook": user,
            "creation": ["between", [from_date, to_date]]
        },
        fields=["name", "shop", "total_price", "status", "creation"],
        order_by="creation desc"
    )
    return orders