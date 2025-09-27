import frappe
from rokct.rokct.control_panel.tasks import create_tenant_site_job
from rokct.rokct.control_panel.provisioning import create_subscription_record

def run_manual_creation():
    """
    Manually triggers the site creation process for debugging purposes.
    This bypasses the API and the background queue.
    """
    print("--- Starting Manual Site Creation Test ---")

    # --- Test Data ---
    plan = "Free (Monthly)"
    email = "test-user-1@example.com"
    first_name = "Test"
    last_name = "User"
    company_name = "Black Wealth Institute"
    currency = "USD"
    country = "United States"
    industry = "Technology"

    user_details = {
        "email": email,
        "password": "a-very-secure-password",
        "first_name": first_name,
        "last_name": last_name,
        "company_name": company_name,
        "currency": currency,
        "country": country,
        "verification_token": frappe.generate_hash(length=48)
    }

    # --- Generate Site Name ---
    tenant_domain = frappe.conf.get("tenant_domain")
    if not tenant_domain:
        print("ERROR: `tenant_domain` not set in control plane site_config.json")
        return

    words = company_name.strip().split()
    if len(words) > 1:
        site_prefix = "".join(word[0] for word in words).lower()
    else:
        site_prefix = words[0].strip().lower().replace('.', '').replace('_', '-').replace(' ', '-')

    site_name = f"{site_prefix}.{tenant_domain}"
    print(f"Generated site name: {site_name}")

    # --- Ensure Prerequisite Records Exist ---
    subscription = None
    try:
        # Clean up previous failed attempts if they exist
        if frappe.db.exists("Company Subscription", {"site_name": site_name}):
            print(f"Found existing failed subscription for {site_name}. Deleting it before retry.")
            frappe.delete_doc("Company Subscription", frappe.db.get_value("Company Subscription", {"site_name": site_name}), force=True, ignore_permissions=True)
            frappe.db.commit()

        if frappe.db.exists("Customer", company_name):
             print(f"Found existing customer '{company_name}'. Deleting it before retry.")
             frappe.delete_doc("Customer", company_name, force=True, ignore_permissions=True)
             frappe.db.commit()

        print("Creating new prerequisite records (Customer, Company Subscription)...")
        subscription = create_subscription_record(plan, company_name, industry, site_name, currency)
        print(f"SUCCESS: Created Company Subscription: {subscription.name}")
    except Exception as e:
        print(f"\n--- FATAL ERROR: Failed to create prerequisite records. ---")
        print(f"Reason: {e}")
        frappe.log_error(frappe.get_traceback(), "Manual Test Prerequisite Failure")
        return

    # --- Manually Execute the Background Job ---
    if subscription:
        try:
            print("\n--- Manually executing create_tenant_site_job function... ---")
            create_tenant_site_job(subscription.name, site_name, user_details)
            print("\n--- Manual execution function finished. Check logs above for details. ---")
        except Exception as e:
            print(f"\n--- FATAL ERROR: The create_tenant_site_job function crashed. ---")
            print(f"Reason: {e}")
            frappe.log_error(frappe.get_traceback(), "Manual Test Execution Failure")
    else:
        print("Could not proceed with job execution because subscription record was not created.")