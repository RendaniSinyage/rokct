import frappe
from frappe import _

def on_trash_customer(doc, method):
    """
    When a Customer is deleted, also delete their associated Company Subscriptions.
    """
    try:
        subscriptions = frappe.get_all("Company Subscription", filters={"customer": doc.name})
        for sub in subscriptions:
            frappe.delete_doc("Company Subscription", sub.name)
            frappe.log_info(
                f"Subscription {sub.name} for customer {doc.name} deleted.",
                "Customer Deletion"
            )
    except Exception as e:
        frappe.log_error(
            message=f"Error deleting subscriptions for customer {doc.name}: {e}",
            title="Customer Deletion Failed"
        )
        # Optional: Uncomment the line below to prevent the customer from being deleted if an error occurs.
        # frappe.throw(_("Could not delete associated company subscriptions."))