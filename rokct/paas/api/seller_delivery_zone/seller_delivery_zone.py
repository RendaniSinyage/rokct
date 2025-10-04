import frappe
from ..utils import _get_seller_shop

@frappe.whitelist()
def get_seller_delivery_zones(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of delivery zones for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    delivery_zones = frappe.get_list(
        "Delivery Zone",
        filters={"shop": shop},
        fields=["name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return delivery_zones


@frappe.whitelist()
def get_seller_delivery_zone(zone_name):
    """
    Retrieves a single delivery zone with its coordinates for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    zone = frappe.get_doc("Delivery Zone", zone_name)

    if zone.shop != shop:
        frappe.throw("You are not authorized to view this delivery zone.", frappe.PermissionError)

    return zone.as_dict()


@frappe.whitelist()
def create_seller_delivery_zone(zone_data):
    """
    Creates a new delivery zone for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(zone_data, str):
        zone_data = json.loads(zone_data)

    zone_data["shop"] = shop

    new_zone = frappe.get_doc({
        "doctype": "Delivery Zone",
        **zone_data
    })
    new_zone.insert(ignore_permissions=True)
    return new_zone.as_dict()


@frappe.whitelist()
def update_seller_delivery_zone(zone_name, zone_data):
    """
    Updates a delivery zone for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(zone_data, str):
        zone_data = json.loads(zone_data)

    zone = frappe.get_doc("Delivery Zone", zone_name)

    if zone.shop != shop:
        frappe.throw("You are not authorized to update this delivery zone.", frappe.PermissionError)

    zone.update(zone_data)
    zone.save(ignore_permissions=True)
    return zone.as_dict()


@frappe.whitelist()
def delete_seller_delivery_zone(zone_name):
    """
    Deletes a delivery zone for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    zone = frappe.get_doc("Delivery Zone", zone_name)

    if zone.shop != shop:
        frappe.throw("You are not authorized to delete this delivery zone.", frappe.PermissionError)

    frappe.delete_doc("Delivery Zone", zone_name, ignore_permissions=True)
    return {"status": "success", "message": "Delivery zone deleted successfully."}