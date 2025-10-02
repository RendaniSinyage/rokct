import frappe
from frappe import _

def on_trash_company_subscription(doc, method):
    """
    When a Company Subscription is deleted, enqueue a job to drop the tenant site.
    """
    try:
        # Reload the document to ensure all fields are loaded, preventing AttributeError.
        doc = frappe.get_doc(doc.doctype, doc.name)

        print(f"Subscription Deletion: on_trash hook triggered for subscription {doc.name}")
        if doc.tenant_site_name:
            print(f"Subscription Deletion: Queueing site deletion for {doc.tenant_site_name}")
            frappe.enqueue(
                "rokct.rokct.control_panel.tasks.drop_tenant_site",
                queue="long",
                site_name=doc.tenant_site_name
            )
            print("Subscription Deletion: Successfully enqueued site deletion job.")
        else:
            print(f"Subscription Deletion: Subscription {doc.name} deleted, but has no tenant_site_name.")
    except Exception:
        print(f"--- ERROR IN on_trash_company_subscription for {doc.name} ---")
        print(frappe.get_traceback())
        frappe.log_error(
            message=f"Error in on_trash_company_subscription for {doc.name}: {frappe.get_traceback()}",
            title="Company Subscription Trash Hook Failed"
        )


def on_update_company_subscription(doc, method):
    """
    When a Company Subscription's status changes to 'Canceled', enqueue a job to drop the tenant site.
    """
    print(f"Subscription Update: on_update hook triggered for {doc.name} with status {doc.status}")
    try:
        # IMPORTANT: Do NOT reload the doc here. It breaks the get_doc_before_save() method.
        # The `doc` object passed to on_update is complete enough for this check.
        doc_before_save = doc.get_doc_before_save()
        if not doc_before_save:
            print("Subscription Update: No doc_before_save found. Exiting.")
            return

        print(f"Subscription Update: Previous status was {doc_before_save.status}")
        status_changed = doc_before_save.status != doc.status

        if status_changed and doc.status.lower() == "canceled":
            print("Subscription Update: Status changed to Canceled.")
            if doc.tenant_site_name:
                print(f"Subscription Update: Queueing site deletion for {doc.tenant_site_name}")
                frappe.enqueue(
                    "rokct.rokct.control_panel.tasks.drop_tenant_site",
                    queue="long",
                    site_name=doc.tenant_site_name
                )
                print("Subscription Update: Successfully enqueued site deletion job.")
            else:
                print(f"Subscription Update: Subscription {doc.name} is canceled, but has no tenant_site_name.")
        else:
            print(f"Subscription Update: Status not changed to Canceled. Old: {doc_before_save.status}, New: {doc.status}")

    except Exception:
        print(f"--- ERROR IN on_update_company_subscription for {doc.name} ---")
        print(frappe.get_traceback())
        frappe.log_error(
            message=f"Error in on_update_company_subscription for {doc.name}: {frappe.get_traceback()}",
            title="Company Subscription Update Hook Failed"
        )