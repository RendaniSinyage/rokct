# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe

def run_fix():
    """
    This script corrects the homepage and default workspace on the control plane.
    It is designed to be run via `bench execute`.
    """
    try:
        # 1. Restore Control Plane Homepage
        website_settings = frappe.get_doc("Website Settings", "Website Settings")
        if website_settings.home_page != "swagger":
            website_settings.home_page = "swagger"
            website_settings.save(ignore_permissions=True)
            print("SUCCESS: Control plane homepage set back to 'swagger'.")
        else:
            print("INFO: Control plane homepage is already set to 'swagger'.")

        # 2. Set Default Workspace for Administrator
        admin_user = frappe.get_doc("User", "Administrator")
        if admin_user.default_workspace != "Platform":
            admin_user.default_workspace = "Platform"
            admin_user.save(ignore_permissions=True)
            print("SUCCESS: Administrator default workspace set to 'Platform'.")
        else:
            print("INFO: Administrator default workspace is already set to 'Platform'.")

        frappe.db.commit()
        print("All settings applied successfully.")

    except Exception as e:
        print(f"ERROR: An error occurred: {e}")
        if frappe.db:
            frappe.db.rollback()

if __name__ == "__main__":
    run_fix()