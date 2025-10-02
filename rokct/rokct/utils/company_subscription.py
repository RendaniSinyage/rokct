import frappe
from frappe import _

def on_trash_company_subscription(doc, method):
    """
    When a Company Subscription is deleted, enqueue a job to drop the tenant site.
    """
    frappe.log(f"on_trash hook triggered for subscription {doc.name}", "Subscription Deletion")
    if doc.tenant_site_name:
        frappe.log(f"Queueing site deletion for {doc.tenant_site_name}", "Subscription Deletion")
        frappe.enqueue(
            "rokct.rokct.control_panel.tasks.drop_tenant_site",
            queue="long",
            site_name=doc.tenant_site_name
        )
        frappe.log("Successfully enqueued site deletion job.", "Subscription Deletion")
    else:
        frappe.log(f"Subscription {doc.name} deleted, but has no tenant_site_name.", "Subscription Deletion")


def on_update_company_subscription(doc, method):
    """
    When a Company Subscription's status changes to 'Canceled', enqueue a job to drop the tenant site.
    """
    frappe.log(f"on_update hook triggered for {doc.name} with status {doc.status}", "Subscription Update")
    try:
        doc_before_save = doc.get_doc_before_save()
        if not doc_before_save:
            frappe.log("No doc_before_save found. Exiting.", "Subscription Update")
            return

        frappe.log(f"Previous status was {doc_before_save.status}", "Subscription Update")
        status_changed = doc_before_save.status != doc.status

        # Use .lower() for case-insensitivity and "canceled" for correct spelling.
        if status_changed and doc.status.lower() == "canceled":
            frappe.log("Status changed to Canceled.", "Subscription Update")
            if doc.tenant_site_name:
                frappe.log(f"Queueing site deletion for {doc.tenant_site_name}", "Subscription Update")
                frappe.enqueue(
                    "rokct.rokct.control_panel.tasks.drop_tenant_site",
                    queue="long",
                    site_name=doc.tenant_site_name
                )
                frappe.log("Successfully enqueued site deletion job.", "Subscription Update")
            else:
                frappe.log(f"Subscription {doc.name} is canceled, but has no tenant_site_name.", "Subscription Update")
        else:
            frappe.log(f"Status not changed to Canceled. Old: {doc_before_save.status}, New: {doc.status}", "Subscription Update")

    except Exception as e:
        frappe.log_error(
            message=f"Error in on_update_company_subscription for {doc.name}: {frappe.get_traceback()}",
            title="Company Subscription Update Hook Failed"
        )