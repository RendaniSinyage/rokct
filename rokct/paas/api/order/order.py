import frappe
import json
from frappe.model.document import Document

@frappe.whitelist(allow_guest=True)
def create_order(order_data):
    """
    Creates a new order.
    """
    if isinstance(order_data, str):
        order_data = json.loads(order_data)

    order = frappe.get_doc({
        "doctype": "Order",
        "user": order_data.get("user"),
        "shop": order_data.get("shop"),
        "status": "New",
        "delivery_type": order_data.get("delivery_type"),
        "currency": order_data.get("currency"),
        "rate": order_data.get("rate"),
        "delivery_fee": order_data.get("delivery_fee"),
        "waiter_fee": order_data.get("waiter_fee"),
        "tax": order_data.get("tax"),
        "commission_fee": order_data.get("commission_fee"),
        "service_fee": order_data.get("service_fee"),
        "total_discount": order_data.get("total_discount"),
        "coupon_code": order_data.get("coupon_code"),
        "location": order_data.get("location"),
        "address": order_data.get("address"),
        "phone": order_data.get("phone"),
        "username": order_data.get("username"),
        "delivery_date": order_data.get("delivery_date"),
        "delivery_time": order_data.get("delivery_time"),
        "note": order_data.get("note"),
    })

    for item in order_data.get("order_items", []):
        order.append("order_items", {
            "product": item.get("product"),
            "quantity": item.get("quantity"),
            "price": item.get("price"),
        })

    order.insert(ignore_permissions=True)

    if order_data.get("coupon_code"):
        coupon = frappe.get_doc("Coupon", {"code": order_data.get("coupon_code")})
        frappe.get_doc({
            "doctype": "Coupon Usage",
            "coupon": coupon.name,
            "user": order.user,
            "order": order.name
        }).insert(ignore_permissions=True)

    return order.as_dict()


@frappe.whitelist()
def list_orders(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of orders for the current user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.")

    orders = frappe.get_list(
        "Order",
        filters={"user": user},
        fields=["name", "shop", "total_price", "status", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_order_details(order_id: str):
    """
    Retrieves the details of a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.")

    order = frappe.get_doc("Order", order_id)
    if order.user != user:
        frappe.throw("You are not authorized to view this order.", frappe.PermissionError)
    return order.as_dict()


@frappe.whitelist()
def update_order_status(order_id: str, status: str):
    """
    Updates the status of a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update an order.")

    order = frappe.get_doc("Order", order_id)

    if order.user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw("You are not authorized to update this order.", frappe.PermissionError)

    valid_statuses = frappe.get_meta("Order").get_field("status").options.split("\n")
    if status not in valid_statuses:
        frappe.throw(f"Invalid status. Must be one of {', '.join(valid_statuses)}")

    order.status = status
    order.save(ignore_permissions=True)
    return order.as_dict()


@frappe.whitelist()
def add_order_review(order_id: str, rating: float, comment: str = None):
    """
    Adds a review for a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to leave a review.")

    order = frappe.get_doc("Order", order_id)

    if order.user != user:
        frappe.throw("You can only review your own orders.", frappe.PermissionError)

    if order.status != "Delivered":
        frappe.throw("You can only review delivered orders.")

    if frappe.db.exists("Review", {"reviewable_type": "Order", "reviewable_id": order_id, "user": user}):
        frappe.throw("You have already reviewed this order.")

    review = frappe.get_doc({
        "doctype": "Review",
        "reviewable_type": "Order",
        "reviewable_id": order_id,
        "user": user,
        "rating": rating,
        "comment": comment,
        "published": 1
    })
    review.insert(ignore_permissions=True)
    return review.as_dict()


@frappe.whitelist()
def cancel_order(order_id: str):
    """
    Cancels a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to cancel an order.")

    order = frappe.get_doc("Order", order_id)

    if order.user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw("You are not authorized to cancel this order.", frappe.PermissionError)

    if order.status != "New":
        frappe.throw("You can only cancel orders that have not been accepted yet.")

    order.status = "Cancelled"

    # Replenish stock by creating a Stock Entry for stock reconciliation
    stock_entry = frappe.get_doc({
        "doctype": "Stock Entry",
        "purpose": "Stock Reconciliation",
        "items": []
    })
    for item in order.order_items:
        stock_entry.append("items", {
            "item_code": item.product,
            "qty": item.quantity,
            "s_warehouse": "Stores", # Or get from product/order
            "t_warehouse": "Stores", # Or get from product/order
            "diff_qty": item.quantity,
            "basic_rate": item.price
        })
    stock_entry.insert(ignore_permissions=True)
    stock_entry.submit()

    order.save(ignore_permissions=True)
    return order.as_dict()

@frappe.whitelist(allow_guest=True)
def get_order_statuses():
    """
    Retrieves a list of active order statuses, formatted for frontend compatibility.
    """
    statuses = frappe.get_list(
        "Order Status",
        filters={"is_active": 1},
        fields=["name", "status_name", "sort_order"],
        order_by="sort_order asc"
    )

    formatted_statuses = []
    for status in statuses:
        formatted_statuses.append({
            "id": status.name,
            "name": status.status_name,
            "active": True,
            "sort": status.sort_order,
        })

    return formatted_statuses