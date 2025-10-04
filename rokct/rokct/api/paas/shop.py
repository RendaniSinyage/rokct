# Copyright (c) 2025, ROKCT and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document
import uuid

@frappe.whitelist()
def create_shop(shop_data):
    """
    Creates a new Shop document.
    Only users with 'System Manager' or 'Seller' roles can create a shop.
    """
    if "System Manager" not in frappe.get_roles() and "Seller" not in frappe.get_roles():
        frappe.throw("You are not authorized to create a shop.", frappe.PermissionError)

    if not isinstance(shop_data, dict):
        frappe.throw("shop_data must be a dictionary.", frappe.ValidationError)

    # Set the current user as the owner if not specified
    if 'user' not in shop_data:
        shop_data['user'] = frappe.session.user

    # Generate UUID and slug
    shop_data['uuid'] = str(uuid.uuid4())
    shop_data['slug'] = frappe.utils.slug(shop_data.get('shop_name'))

    try:
        shop = frappe.get_doc({
            "doctype": "Shop",
            **shop_data
        })
        shop.insert(ignore_permissions=True)
        frappe.db.commit()
        return shop.as_dict()
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Shop Creation Failed")
        frappe.throw(f"An error occurred while creating the shop: {e}")

@frappe.whitelist(allow_guest=True)
def get_shops(limit_start: int = 0, limit_page_length: int = 20, order_by: str = "name", order: str = "desc", **kwargs):
    """
    Retrieves a list of shops with pagination and filters.
    """
    filters = {
        "status": "approved",
        "visibility": 1,
        "open": 1
    }

    if kwargs.get("delivery"):
        filters["delivery"] = 1

    if kwargs.get("takeaway"):
        filters["pickup"] = 1

    shops = frappe.get_list(
        "Shop",
        filters=filters,
        fields=[
            "name", "uuid", "slug", "user", "logo", "cover_photo",
            "phone", "address", "location", "status", "type", "min_amount",
            "tax", "delivery_time_type", "delivery_time_from", "delivery_time_to",
            "open", "visibility", "verify", "service_fee", "percentage"
        ],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by=f"{order_by} {order}"
    )

    # Replicating the structure of the legacy ShopResource
    formatted_shops = []
    for shop in shops:
        formatted_shops.append({
            'id': shop.name,
            'uuid': shop.uuid,
            'slug': shop.slug,
            'user_id': shop.user,
            'tax': shop.tax,
            'service_fee': shop.service_fee,
            'percentage': shop.percentage,
            'phone': shop.phone,
            'open': bool(shop.open),
            'visibility': bool(shop.visibility),
            'verify': bool(shop.verify),
            'logo_img': shop.logo,
            'background_img': shop.cover_photo,
            'min_amount': shop.min_amount,
            'status': shop.status,
            'delivery_time': {
                'type': shop.delivery_time_type,
                'from': shop.delivery_time_from,
                'to': shop.delivery_time_to
            },
            'location': shop.location,
            'translation': {
                'title': shop.name,
                'address': shop.address
            }
        })

    return formatted_shops

@frappe.whitelist(allow_guest=True)
def get_shop_details(uuid: str):
    """
    Retrieves a single shop by its UUID.
    """
    shop = frappe.get_doc("Shop", {"uuid": uuid})

    if not shop:
        frappe.throw(f"Shop with UUID {uuid} not found.", frappe.DoesNotExistError)

    # Replicating the structure of the legacy ShopResource
    return {
        'id': shop.name,
        'uuid': shop.uuid,
        'slug': shop.slug,
        'user_id': shop.user,
        'tax': shop.tax,
        'service_fee': shop.service_fee,
        'percentage': shop.percentage,
        'phone': shop.phone,
        'open': bool(shop.open),
        'visibility': bool(shop.visibility),
        'verify': bool(shop.verify),
        'logo_img': shop.logo,
        'background_img': shop.cover_photo,
        'min_amount': shop.min_amount,
        'status': shop.status,
        'delivery_time': {
            'type': shop.delivery_time_type,
            'from': shop.delivery_time_from,
            'to': shop.delivery_time_to
        },
        'location': shop.location,
        'translation': {
            'title': shop.name,
            'address': shop.address
        }
    }