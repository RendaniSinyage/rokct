import frappe
import json
from rokct.rokct.control_panel.tasks import create_tenant_site_job, complete_tenant_setup
from rokct.rokct.control_panel.provisioning import create_subscription_record

@frappe.whitelist()
def trigger_provisioning_for_debug():
    """
    A temporary debug utility to run the tenant provisioning process synchronously
    and see the output directly in the terminal.
    """
    details = {
        "plan": "Free (Yearly)",
        "email": "blackwealth@juvo.app",
        "password": "Linkme78#@",
        "first_name": "Rendani",
        "last_name": "Sinyage",
        "company_name": "Black Wealth Institute",
        "currency": "USD",
        "country": "South Africa",
        "industry": "Technology"
    }
    site_name = "bwi.tenant.rokct.ai"

    print(f"--- Starting FULLY SYNCHRONOUS Debug Provisioning for {site_name} ---")
    frappe.flags.from_console = True # To enable extra logging

    # Clean up existing failed subscription if it exists
    if frappe.db.exists("Company Subscription", {"site_name": site_name}):
        frappe.delete_doc("Company Subscription", frappe.db.get_value("Company Subscription", {"site_name": site_name}), force=True)
        print(f"--- Deleted existing subscription for {site_name} ---")

    # 1. Create a new subscription record
    try:
        subscription = create_subscription_record(
            plan=details["plan"],
            company_name=details["company_name"],
            industry=details["industry"],
            site_name=site_name,
            currency=details["currency"]
        )
        print(f"--- Created new subscription record: {subscription.name} ---")
    except Exception as e:
        print(f"--- FAILED to create subscription record ---")
        frappe.log_error(frappe.get_traceback(), "Debug Provisioning Error")
        return

    # Add verification token to user_details
    user_details = details.copy()
    user_details["verification_token"] = frappe.generate_hash(length=48)

    # 2. Run the site creation job synchronously
    try:
        print("\n--- Running create_tenant_site_job synchronously ---")
        create_tenant_site_job(
            subscription_id=subscription.name,
            site_name=site_name,
            user_details=user_details,
            synchronous=True # This is the key change
        )
        print("--- Finished create_tenant_site_job ---")
    except Exception as e:
        print(f"--- FAILED during create_tenant_site_job ---")
        # The job itself now has better logging, so we don't need to log the traceback here.
        # frappe.log_error(frappe.get_traceback(), "Debug Provisioning Error")
        return # Stop if site creation fails

    # 3. Run the final setup job synchronously
    try:
        print("\n--- Running complete_tenant_setup synchronously ---")
        complete_tenant_setup(
            subscription_id=subscription.name,
            site_name=site_name,
            user_details=user_details
        )
        print("--- Finished complete_tenant_setup ---")
        print("\n--- SYNCHRONOUS DEBUG PROVISIONING COMPLETE ---")
    except Exception as e:
        print(f"--- FAILED during complete_tenant_setup ---")
        # Explicitly print the traceback to the console for immediate diagnosis.
        print("\n--- TRACEBACK ---")
        print(frappe.get_traceback())
        print("--- END TRACEBACK ---\n")
        frappe.log_error(frappe.get_traceback(), "Debug Provisioning Error")