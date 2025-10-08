# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document


class DeliveryPoint(Document):
	pass


@frappe.whitelist()
def get_nearest_delivery_points(latitude, longitude, radius=20):
    """
    Get nearest delivery points based on latitude and longitude.
    :param latitude: User's latitude
    :param longitude: User's longitude
    :param radius: Search radius in kilometers (default: 20)
    :return: List of nearest delivery points
    """
    if not latitude or not longitude:
        frappe.throw("Latitude and Longitude are required.")

    try:
        latitude = float(latitude)
        longitude = float(longitude)
        radius = float(radius)
    except ValueError:
        frappe.throw("Invalid coordinates or radius.")

    # Haversine formula to calculate distance, using parameterized queries to prevent SQL injection
    query = """
        SELECT
            name,
            address,
            latitude,
            longitude,
            img,
            (
                6371 * acos(
                    cos(radians(%(latitude)s))
                    * cos(radians(latitude))
                    * cos(radians(longitude) - radians(%(longitude)s))
                    + sin(radians(%(latitude)s))
                    * sin(radians(latitude))
                )
            ) AS distance
        FROM `tabDelivery Point`
        WHERE active = 1
        HAVING distance < %(radius)s
        ORDER BY distance
        LIMIT 20
    """

    values = {
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius
    }

    delivery_points = frappe.db.sql(query, values, as_dict=True)

    return delivery_points