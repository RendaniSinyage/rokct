# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document

# Admin Booking Management

@frappe.whitelist()
def create_booking(data):
    """Create a new booking."""
    if not frappe.has_permission("Booking", "create"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc(data)
    doc.insert()
    return doc

@frappe.whitelist()
def get_booking(name):
    """Get a booking by name."""
    if not frappe.has_permission("Booking", "read"):
        frappe.throw("Not permitted", frappe.PermissionError)
    return frappe.get_doc("Booking", name)

@frappe.whitelist()
def update_booking(name, data):
    """Update a booking."""
    if not frappe.has_permission("Booking", "write"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc("Booking", name)
    doc.update(data)
    doc.save()
    return doc

@frappe.whitelist()
def delete_booking(name):
    """Delete a booking."""
    if not frappe.has_permission("Booking", "delete"):
        frappe.throw("Not permitted", frappe.PermissionError)
    frappe.delete_doc("Booking", name)
    return {"status": "success", "message": "Booking deleted successfully"}

# Admin Shop Section Management

@frappe.whitelist()
def create_shop_section(data):
    """Create a new shop section."""
    if not frappe.has_permission("Shop Section", "create"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc(data)
    doc.insert()
    return doc

@frappe.whitelist()
def get_shop_section(name):
    """Get a shop section by name."""
    if not frappe.has_permission("Shop Section", "read"):
        frappe.throw("Not permitted", frappe.PermissionError)
    return frappe.get_doc("Shop Section", name)

@frappe.whitelist()
def update_shop_section(name, data):
    """Update a shop section."""
    if not frappe.has_permission("Shop Section", "write"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc("Shop Section", name)
    doc.update(data)
    doc.save()
    return doc

@frappe.whitelist()
def delete_shop_section(name):
    """Delete a shop section."""
    if not frappe.has_permission("Shop Section", "delete"):
        frappe.throw("Not permitted", frappe.PermissionError)
    frappe.delete_doc("Shop Section", name)
    return {"status": "success", "message": "Shop Section deleted successfully"}

# Admin Table Management

@frappe.whitelist()
def create_table(data):
    """Create a new table."""
    if not frappe.has_permission("Table", "create"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc(data)
    doc.insert()
    return doc

@frappe.whitelist()
def get_table(name):
    """Get a table by name."""
    if not frappe.has_permission("Table", "read"):
        frappe.throw("Not permitted", frappe.PermissionError)
    return frappe.get_doc("Table", name)

@frappe.whitelist()
def update_table(name, data):
    """Update a table."""
    if not frappe.has_permission("Table", "write"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc("Table", name)
    doc.update(data)
    doc.save()
    return doc

@frappe.whitelist()
def delete_table(name):
    """Delete a table."""
    if not frappe.has_permission("Table", "delete"):
        frappe.throw("Not permitted", frappe.PermissionError)
    frappe.delete_doc("Table", name)
    return {"status": "success", "message": "Table deleted successfully"}

# Admin User Booking Management

@frappe.whitelist()
def get_user_bookings(user=None):
    """Get all user bookings, optionally filtered by user."""
    if not frappe.has_permission("User Booking", "read"):
        frappe.throw("Not permitted", frappe.PermissionError)
    filters = {}
    if user:
        filters['user'] = user
    return frappe.get_list("User Booking", filters=filters, fields=["*"])

@frappe.whitelist()
def update_user_booking_status(name, status):
    """Update the status of a user booking."""
    if not frappe.has_permission("User Booking", "write"):
        frappe.throw("Not permitted", frappe.PermissionError)
    doc = frappe.get_doc("User Booking", name)
    doc.status = status
    doc.save()
    return doc

# User Booking Management

@frappe.whitelist()
def get_shop_bookings(shop_id):
    """Get all bookings for a specific shop."""
    return frappe.get_list("Booking", filters={"shop": shop_id, "active": 1}, fields=["*"])

@frappe.whitelist()
def get_shop_sections_for_booking(shop_id):
    """Get all shop sections for a specific shop."""
    return frappe.get_list("Shop Section", filters={"shop": shop_id}, fields=["*"])

@frappe.whitelist()
def get_tables_for_section(shop_section_id):
    """Get all tables for a specific shop section."""
    return frappe.get_list("Table", filters={"shop_section": shop_section_id, "active": 1}, fields=["*"])

@frappe.whitelist()
def create_user_booking(data):
    """Create a new user booking."""
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to create a booking.", frappe.PermissionError)

    booking_data = frappe._dict(data)
    booking_data.user = user
    booking_data.doctype = "User Booking"

    doc = frappe.get_doc(booking_data)
    doc.insert(ignore_permissions=True)
    return doc

@frappe.whitelist()
def get_my_bookings():
    """Get the current user's bookings."""
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your bookings.", frappe.PermissionError)

    return frappe.get_list("User Booking", filters={"user": user}, fields=["*"])

@frappe.whitelist()
def cancel_my_booking(name):
    """Cancel a user's booking."""
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to cancel a booking.", frappe.PermissionError)

    doc = frappe.get_doc("User Booking", name)
    if doc.user != user:
        frappe.throw("You can only cancel your own bookings.", frappe.PermissionError)

    doc.status = "Cancelled"
    doc.save(ignore_permissions=True)
    return doc

# Seller & Waiter Booking Management

def check_shop_permission(shop_id, role):
    """Check if the current user has permission for a given shop."""
    user = frappe.session.user
    if frappe.has_role("System Manager"):
        return

    if not frappe.db.exists("Shop User", {"user": user, "shop": shop_id, "role": role}):
        frappe.throw(f"You are not authorized to manage this shop's {role.lower()} bookings.", frappe.PermissionError)

@frappe.whitelist()
def get_shop_user_bookings(shop_id):
    """Get all user bookings for a specific shop."""
    check_shop_permission(shop_id, "Seller")

    bookings = frappe.get_all("User Booking", filters={"booking.shop": shop_id}, fields=["*"])
    return bookings

@frappe.whitelist()
def update_shop_user_booking_status(name, status):
    """Update the status of a user booking for a shop."""
    doc = frappe.get_doc("User Booking", name)
    booking = frappe.get_doc("Booking", doc.booking)
    check_shop_permission(booking.shop, "Seller")

    doc.status = status
    doc.save(ignore_permissions=True)
    return doc

@frappe.whitelist()
def manage_shop_booking_working_days(shop_id, working_days):
    """Manage the booking working days for a shop."""
    check_shop_permission(shop_id, "Seller")

    shop = frappe.get_doc("Shop", shop_id)
    shop.booking_working_days = []
    for day in working_days:
        shop.append("booking_working_days", day)
    shop.save()
    return shop

@frappe.whitelist()
def manage_shop_booking_closed_dates(shop_id, closed_dates):
    """Manage the booking closed dates for a shop."""
    check_shop_permission(shop_id, "Seller")

    shop = frappe.get_doc("Shop", shop_id)
    shop.booking_closed_dates = []
    for date in closed_dates:
        shop.append("booking_closed_dates", date)
    shop.save()
    return shop