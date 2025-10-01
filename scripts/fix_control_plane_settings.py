import frappe
import os

def run_fix():
    try:
        # Manually initialize the Frappe framework for the control plane site
        frappe.init(site="platform.rokct.ai")
        frappe.connect()

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
    finally:
        # Disconnect from the database
        if frappe.db:
            frappe.db.close()
        frappe.destroy()

if __name__ == "__main__":
    run_fix()