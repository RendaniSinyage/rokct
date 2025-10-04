import frappe

def _get_seller_shop(user_id):
    """Helper function to get the shop for a given user."""
    if not user_id or user_id == "Guest":
        frappe.throw("You must be logged in to perform this action.", frappe.AuthenticationError)

    # Assuming 'user_id' is a custom field on the Company doctype linking to the User
    shop = frappe.db.get_value("Company", {"user_id": user_id}, "name")
    if not shop:
        frappe.throw("User is not linked to any shop.", frappe.PermissionError)

    return shop