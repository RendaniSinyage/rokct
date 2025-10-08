import frappe
import json

@frappe.whitelist()
def create_parcel_order(order_data):
    """
    Creates a new parcel order.
    """
    if isinstance(order_data, str):
        order_data = json.loads(order_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to create a parcel order.", frappe.AuthenticationError)

    parcel_order = frappe.get_doc({
        "doctype": "Parcel Order",
        "user": user,
        "total_price": order_data.get("total_price"),
        "currency": order_data.get("currency"),
        "type": order_data.get("type"),
        "note": order_data.get("note"),
        "tax": order_data.get("tax"),
        "status": "New",
        "sales_order": order_data.get("sales_order_id"),
        "delivery_point": order_data.get("delivery_point_id"),
        "address_from": json.dumps(order_data.get("address_from")),
        "phone_from": order_data.get("phone_from"),
        "username_from": order_data.get("username_from"),
        "address_to": json.dumps(order_data.get("address_to")),
        "phone_to": order_data.get("phone_to"),
        "username_to": order_data.get("username_to"),
        "delivery_fee": order_data.get("delivery_fee"),
        "delivery_date": order_data.get("delivery_date"),
        "delivery_time": order_data.get("delivery_time"),
    })

    items = order_data.get("items", [])
    for item in items:
        parcel_order.append("items", {
            "item": item.get("item_code"),
            "item_name": item.get("item_name"),
            "quantity": item.get("quantity"),
            "sales_order_item": item.get("sales_order_item")
        })

    parcel_order.insert(ignore_permissions=True)
    return parcel_order.as_dict()

@frappe.whitelist()
def get_parcel_orders(limit=20, offset=0):
    """
    Retrieves a paginated list of parcel orders for the current user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view parcel orders.", frappe.AuthenticationError)

    parcel_orders = frappe.get_list(
        "Parcel Order",
        filters={"user": user},
        fields=["name", "status", "delivery_date", "total_price", "address_to"],
        limit_page_length=limit,
        start=offset,
        order_by="modified desc"
    )

    return parcel_orders