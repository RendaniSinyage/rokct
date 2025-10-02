import frappe
from frappe import _

def on_trash_company_subscription(doc, method):
    """
    When a Company Subscription is deleted, enqueue a job to drop the tenant site.
    """
    if doc.tenant_site_name:
        frappe.enqueue(
            "rokct.rokct.control_panel.tasks.drop_tenant_site",
            queue="long",
            site_name=doc.tenant_site_name
        )
        frappe.log_info(
            f"Queued site deletion for {doc.tenant_site_name}.",
            "Company Subscription Deletion"
        )

def on_update_company_subscription(doc, method):
    """
    When a Company Subscription's status changes to 'Cancelled', enqueue a job to drop the tenant site.
    """
    try:
        doc_before_save = doc.get_doc_before_save()
        if not doc_before_save:
            return

        status_changed = doc_before_save.status != doc.status

        if status_changed and doc.status == "Cancelled":
            if doc.tenant_site_name:
                frappe.enqueue(
                    "rokct.rokct.control_panel.tasks.drop_tenant_site",
                    queue="long",
                    site_name=doc.tenant_site_name
                )
                frappe.log_info(
                    f"Queued site deletion for {doc.tenant_site_name} due to cancellation.",
                    "Company Subscription Cancellation"
                )
    except Exception as e:
        frappe.log_error(
            message=f"Error in on_update_company_subscription for {doc.name}: {frappe.get_traceback()}",
            title="Company Subscription Update Hook Failed"
        )