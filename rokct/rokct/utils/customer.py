import frappe
from frappe import _

def on_trash_customer(doc, method):
    """
    When a Customer is deleted, also delete their associated Company Subscriptions.
    This is triggered by the on_trash hook.
    """
    try:
        # frappe.log_info(f"Attempting to delete subscriptions for customer {doc.name}", "Customer Deletion")
        subscriptions = frappe.get_all("Company Subscription", filters={"customer": doc.name})

        if not subscriptions:
            # frappe.log_info(f"No subscriptions found for customer {doc.name}.", "Customer Deletion")
            return

        for sub in subscriptions:
            # frappe.log_info(f"Deleting subscription {sub.name} for customer {doc.name}.", "Customer Deletion")
            frappe.delete_doc("Company Subscription", sub.name, ignore_permissions=True, force_delete=True)

        # frappe.log_info(f"Successfully processed on_trash_customer for {doc.name}", "Customer Deletion")

    except Exception as e:
        frappe.log_error(
            message=f"Error in on_trash_customer for {doc.name}: {frappe.get_traceback()}",
            title="Customer Deletion Hook Failed"
        )
        # Do not re-throw the exception, as it might prevent the customer from being deleted.
        # The error is logged for investigation.