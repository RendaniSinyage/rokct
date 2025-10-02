import frappe
from frappe import _

def on_trash_customer(doc, method):
    """
    When a Customer is deleted, enqueue a background job to delete their
    associated data, such as company subscriptions.
    """
    try:
        frappe.log(f"Customer Deletion: on_trash_customer hook triggered for {doc.name}")
        frappe.enqueue(
            "rokct.rokct.control_panel.tasks.delete_customer_data",
            queue="long",
            customer_name=doc.name
        )
        frappe.log(
            f"Customer Deletion: Successfully enqueued data deletion job for customer {doc.name}."
        )
    except Exception as e:
        frappe.log_error(
            message=f"Failed to enqueue data deletion job for customer {doc.name}: {frappe.get_traceback()}",
            title="Customer Deletion Hook Failed"
        )
        # It's important to log the error but not re-throw it,
        # so the customer deletion itself can complete.