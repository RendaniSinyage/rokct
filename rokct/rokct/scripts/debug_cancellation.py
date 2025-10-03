# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe

@frappe.whitelist()
def trigger_cancellation_for_debug(site_name):
    """
    A debug utility to run the tenant cancellation process synchronously
    and see the output directly in the terminal.
    """
    print("--- Starting Debug Cancellation ---")
    print(f"Target site: {site_name}")

    if not site_name:
        print("!!! ERROR: Please provide a site_name to cancel.")
        return

    # 1. Find the subscription
    subscription_name = frappe.db.get_value("Company Subscription", {"site_name": site_name}, "name")
    if not subscription_name:
        print(f"!!! ERROR: No active subscription found for site '{site_name}'")
        return

    print(f"Found subscription: {subscription_name}")

    # 2. Get the document and change the status
    try:
        subscription_doc = frappe.get_doc("Company Subscription", subscription_name)
        print(f"Current status is: '{subscription_doc.status}'")

        if subscription_doc.status == "Canceled":
            print("Subscription is already canceled. To re-trigger the hook, you must change the status to something else first, save, then run this script again.")
            return

        print("Setting status to 'Canceled'...")
        subscription_doc.status = "Canceled"

        # The on_update hook is triggered by the save() method
        print("Saving document to trigger on_update hook...")
        subscription_doc.save(ignore_permissions=True)
        frappe.db.commit()
        print("Save complete. The 'on_update' hook should have executed.")
        print("--- Debug Cancellation Script Finished ---")

    except Exception as e:
        print(f"!!! AN ERROR OCCURRED !!!")
        print(frappe.get_traceback())
        frappe.log_error(frappe.get_traceback(), "Debug Cancellation Failed")
        return