import frappe
from frappe import _

def on_trash_customer(doc, method):
    """
    When a Customer is deleted, find all their subscriptions and change
    the status to 'Canceled'. This will then trigger the on_update hook
    of the subscription, which handles the site deletion.
    """
    try:
        print(f"Customer Deletion: on_trash_customer hook triggered for {doc.name}")
        subscriptions = frappe.get_all("Company Subscription", filters={"customer": doc.name})

        if not subscriptions:
            print(f"Customer Deletion: No subscriptions found for customer {doc.name}.")
            return

        for sub_info in subscriptions:
            try:
                subscription = frappe.get_doc("Company Subscription", sub_info.name)
                subscription.status = "Canceled"
                subscription.save(ignore_permissions=True)
                print(f"Customer Deletion: Set status to Canceled for subscription {subscription.name}")
            except Exception:
                print(f"--- ERROR canceling subscription {sub_info.name} ---")
                print(frappe.get_traceback())
                # Log error but continue, so we attempt to cancel other subscriptions.
                frappe.log_error(
                    message=f"Failed to cancel subscription {sub_info.name} for customer {doc.name}: {frappe.get_traceback()}",
                    title="Subscription Cancellation Failed during Customer Deletion"
                )

        print(f"Customer Deletion: Finished processing subscriptions for {doc.name}.")

    except Exception:
        print(f"--- ERROR IN on_trash_customer for {doc.name} ---")
        print(frappe.get_traceback())
        frappe.log_error(
            message=f"Failed to process subscriptions for customer {doc.name}: {frappe.get_traceback()}",
            title="Customer Deletion Hook Failed"
        )