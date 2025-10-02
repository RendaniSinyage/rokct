import frappe
from frappe import _

def on_update_company_subscription(doc, method):
    """
    When a Company Subscription's status changes to 'Canceled', enqueue a job to drop the tenant site.
    """
    print(f"Subscription Update: on_update hook triggered for {doc.name} with status {doc.status}")
    try:
        doc_before_save = doc.get_doc_before_save()
        if not doc_before_save:
            print("Subscription Update: No doc_before_save found. Exiting.")
            return

        print(f"Subscription Update: Previous status was {doc_before_save.status}")
        status_changed = doc_before_save.status != doc.status

        if status_changed and doc.status.lower() == "canceled":
            print("Subscription Update: Status changed to Canceled.")
            site_name = frappe.db.get_value("Company Subscription", doc.name, "tenant_site_name")
            if site_name:
                print(f"Subscription Update: Queueing site deletion for {site_name}")
                # Use is_async=False to run the job immediately via the scheduler from a web worker
                frappe.enqueue(
                    "rokct.rokct.control_panel.tasks.drop_tenant_site",
                    queue="long",
                    is_async=False,
                    site_name=site_name
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