import frappe
import json

@frappe.whitelist()
def create_parcel_order(order_data):
    """
    Creates a new parcel order from a flexible payload.
    'order_data' is a JSON string or dict with parcel details.
    """
    if isinstance(order_data, str):
        order_data = json.loads(order_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to create a parcel order.", frappe.AuthenticationError)

    paas_settings = frappe.get_single("PaaS Settings")
    initial_status = "Accepted" if paas_settings.auto_approve_parcel_orders else "New"

    new_parcel_doc = {
        "doctype": "Parcel Order",
        "user": user,
        "total_price": order_data.get("total_price"),
        "currency": order_data.get("currency"),
        "type": order_data.get("type"),
        "note": order_data.get("note"),
        "tax": order_data.get("tax"),
        "status": initial_status,
        "phone_from": order_data.get("phone_from"),
        "username_from": order_data.get("username_from"),
        "phone_to": order_data.get("phone_to"),
        "username_to": order_data.get("username_to"),
        "delivery_fee": order_data.get("delivery_fee"),
        "delivery_date": order_data.get("delivery_date"),
        "delivery_time": order_data.get("delivery_time"),
    }

    # Handle different destination types
    destination_type = order_data.get("destination_type")

    if destination_type == "customer" and order_data.get("customer_id"):
        customer = frappe.get_doc("User", order_data.get("customer_id"))
        new_parcel_doc["username_to"] = customer.get("full_name")
        new_parcel_doc["phone_to"] = customer.get("phone")
        new_parcel_doc["address_to"] = f"Customer: {customer.get('full_name')}"

    elif destination_type == "delivery_point" and order_data.get("delivery_point_id"):
        delivery_point = frappe.get_doc("Delivery Point", order_data.get("delivery_point_id"))
        new_parcel_doc["delivery_point"] = delivery_point.name
        new_parcel_doc["address_to"] = delivery_point.address
        new_parcel_doc["username_to"] = f"Pickup Point: {delivery_point.name}"

    elif destination_type == "custom_location" and order_data.get("address_to"):
        new_parcel_doc["address_to"] = json.dumps(order_data.get("address_to"))
        new_parcel_doc["address_from"] = json.dumps(order_data.get("address_from"))

    else:
        # Handle reverse logistics or other cases
        new_parcel_doc["address_from"] = json.dumps(order_data.get("address_from"))
        new_parcel_doc["address_to"] = json.dumps(order_data.get("address_to"))

    # Link Sales Order if provided
    if order_data.get("sales_order_id"):
        new_parcel_doc["sales_order"] = order_data.get("sales_order_id")

    # Link Parcel Option if provided
    if order_data.get("parcel_option_id"):
        new_parcel_doc["parcel_option"] = order_data.get("parcel_option_id")

    parcel_order = frappe.get_doc(new_parcel_doc)

    # Add items if they exist
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
        fields=["name", "status", "delivery_date", "total_price", "address_to", "delivery_point", "sales_order"],
        limit_page_length=limit,
        start=offset,
        order_by="modified desc"
    )

    return parcel_orders

@frappe.whitelist()
def update_parcel_status(parcel_order_id, status):
    """
    Updates the status of a specific parcel order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update a parcel order.", frappe.AuthenticationError)

    try:
        parcel_order = frappe.get_doc("Parcel Order", parcel_order_id)

        # Basic ownership/permission check
        if parcel_order.user != user:
            frappe.throw("You are not authorized to update this parcel order.", frappe.PermissionError)

        # TODO: Add more robust status transition validation logic here

        parcel_order.status = status
        parcel_order.save(ignore_permissions=True)
        frappe.db.commit()

        return parcel_order.as_dict()
    except frappe.DoesNotExistError:
        frappe.throw(f"Parcel Order {parcel_order_id} not found.", frappe.DoesNotExistError)
    except Exception as e:
        frappe.throw(f"An error occurred: {str(e)}")