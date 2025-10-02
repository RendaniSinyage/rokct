import frappe
from frappe import _

def on_trash_company_subscription(doc, method):
    """
    When a Company Subscription is deleted, enqueue a job to drop the tenant site.
    """
    try:
        # Reload the document to ensure all fields are loaded, preventing AttributeError.
        # This is crucial because the doc object in on_trash can be a shallow copy.
        doc = frappe.get_doc(doc.doctype, doc.name)

        frappe.log(f"Subscription Deletion: on_trash hook triggered for subscription {doc.name}")
        if doc.tenant_site_name:
            frappe.log(f"Subscription Deletion: Queueing site deletion for {doc.tenant_site_name}")
            frappe.enqueue(
                "rokct.rokct.control_panel.tasks.drop_tenant_site",
                queue="long",
                site_name=doc.tenant_site_name
            )
            frappe.log("Subscription Deletion: Successfully enqueued site deletion job.")
        else:
            frappe.log(f"Subscription Deletion: Subscription {doc.name} deleted, but has no tenant_site_name.")
    except Exception as e:
        frappe.log_error(
            message=f"Error in on_trash_company_subscription for {doc.name}: {frappe.get_traceback()}",
            title="Company Subscription Trash Hook Failed"
        )


def on_update_company_subscription(doc, method):
    """
    When a Company Subscription's status changes to 'Canceled', enqueue a job to drop the tenant site.
    """
    try:
        # Reload the document to ensure all fields are loaded, preventing AttributeError.
        doc = frappe.get_doc(doc.doctype, doc.name)
        doc_before_save = doc.get_doc_before_save()
        frappe.log(f"Subscription Update: on_update hook triggered for {doc.name} with status {doc.status}")
        if not doc_before_save:
            frappe.log("Subscription Update: No doc_before_save found. Exiting.")
            return

        frappe.log(f"Subscription Update: Previous status was {doc_before_save.status}")
        status_changed = doc_before_save.status != doc.status

        # Use .lower() for case-insensitivity and "canceled" for correct spelling.
        if status_changed and doc.status.lower() == "canceled":
            frappe.log("Subscription Update: Status changed to Canceled.")
            if doc.tenant_site_name:
                frappe.log(f"Subscription Update: Queueing site deletion for {doc.tenant_site_name}")
                frappe.enqueue(
                    "rokct.rokct.control_panel.tasks.drop_tenant_site",
                    queue="long",
                    site_name=doc.tenant_site_name
                )
                frappe.log("Subscription Update: Successfully enqueued site deletion job.")
            else:
                frappe.log(f"Subscription Update: Subscription {doc.name} is canceled, but has no tenant_site_name.")
        else:
            frappe.log(f"Subscription Update: Status not changed to Canceled. Old: {doc_before_save.status}, New: {doc.status}")

    except Exception as e:
        frappe.log_error(
            message=f"Error in on_update_company_subscription for {doc.name}: {frappe.get_traceback()}",
            title="Company Subscription Update Hook Failed"
        )