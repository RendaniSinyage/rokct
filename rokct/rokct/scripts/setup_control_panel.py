import frappe
import os
import json

@frappe.whitelist()
def configure_control_panel():
    """
    A utility function to be run manually from the bench to apply critical
    configurations to the control panel site (`platform.rokct.ai`).
    """
    if frappe.local.site != "platform.rokct.ai":
        print(f"ERROR: This script is only intended to be run on the 'platform.rokct.ai' site. You are currently on '{frappe.local.site}'.")
        return

    print("--- Running Manual Configuration for Control Panel ---")

    try:
        # --- Step 1: Set values in site_config.json ---
        bench_path = frappe.utils.get_bench_path()
        common_config_path = os.path.join(bench_path, "sites", "common_site_config.json")

        if os.path.exists(common_config_path):
            with open(common_config_path, 'r') as f:
                common_config = json.load(f)

            db_root_password = common_config.get("db_root_password")
            if db_root_password:
                frappe.conf.set_value("db_root_password", db_root_password)
                print("SUCCESS: Set 'db_root_password' in site_config.json")
            else:
                print("SKIPPED: 'db_root_password' not found in common_site_config.json. This is required for provisioning.")
        else:
            print("SKIPPED: common_site_config.json not found.")

        frappe.conf.set_value("app_role", "control_panel")
        print("SUCCESS: Set 'app_role' to 'control_panel' in site_config.json")
        frappe.conf.set_value("tenant_domain", "tenant.rokct.ai")
        print("SUCCESS: Set 'tenant_domain' to 'tenant.rokct.ai' in site_config.json")

        # --- Step 2: Set default values in System Settings ---
        system_settings = frappe.get_doc("System Settings")
        # Defensively check if email_sender attribute exists before accessing it
        if hasattr(system_settings, "email_sender"):
            if not system_settings.email_sender:
                admin_user = frappe.get_doc("User", "Administrator")
                if admin_user and admin_user.email:
                    system_settings.email_sender = admin_user.email
                    system_settings.save(ignore_permissions=True)
                    print(f"SUCCESS: Set default 'Email Sender' in System Settings to '{admin_user.email}'")
                else:
                    print("SKIPPED: Could not set default email sender, Administrator email not found.")
            else:
                print("SKIPPED: Default 'Email Sender' is already set in System Settings.")
        else:
            print("SKIPPED: The 'email_sender' field does not exist in System Settings for this version.")

        frappe.db.commit()
        print("\n--- Manual Configuration Complete ---")
        print("You should now be able to provision new tenants without being prompted for a password.")

    except Exception as e:
        print(f"ERROR: An unexpected error occurred during manual configuration. Reason: {e}")
        frappe.log_error(frappe.get_traceback(), "Manual Control Panel Setup Error")