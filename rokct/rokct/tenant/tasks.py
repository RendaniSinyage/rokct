import frappe
from frappe.utils import now_datetime
from rokct.tenant.utils import send_tenant_email

def update_storage_usage():
    """
    Calculates the total storage usage for the site and updates the
    Storage Settings singleton. Runs as a daily background job.
    """
    if frappe.conf.get("app_role") != "tenant":
        return

    frappe.log("Running Daily Storage Usage Calculation Job...", "Storage Usage Job")

    try:
        # Calculate total file size in bytes from the database
        total_size_bytes = frappe.db.sql("SELECT SUM(file_size) FROM `tabFile`")[0][0] or 0

        # Convert bytes to megabytes for storing
        total_size_mb = total_size_bytes / (1024 * 1024)

        # Update the singleton doctype
        storage_settings = frappe.get_doc("Storage Settings")
        storage_settings.current_storage_usage_mb = total_size_mb
        storage_settings.save(ignore_permissions=True)
        frappe.db.commit()

        frappe.log(f"Successfully updated storage usage to {total_size_mb:.2f} MB.", "Storage Usage Job")

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(
            f"An unexpected error occurred during storage usage calculation: {e}\\n{frappe.get_traceback()}",
            "Storage Usage Job Failed"
        )

def disable_expired_support_users():
    """
    Find and disable temporary support users whose access has expired.
    This is run daily by the scheduler on tenant sites.
    """
    if frappe.conf.get("app_role") != "tenant":
        return

    print("Running Daily Expired Support User Cleanup Job...")

    expired_users = frappe.get_all("User",
        filters={
            "enabled": 1,
            "temporary_user_expires_on": ["<", now_datetime()]
        },
        fields=["name", "email", "first_name"]
    )

    if not expired_users:
        print("No expired support users to disable.")
        return

    print(f"Found {len(expired_users)} expired support users to disable...")

    # Get all system managers to notify them
    system_managers = frappe.get_all("User",
        filters={"role_profile_name": "System Manager", "enabled": 1},
        fields=["email"]
    )
    recipients = [user.email for user in system_managers]

    if not recipients:
        print("No System Managers found to notify.")
        # Still proceed to disable the user, but log it
        frappe.log_error("No System Managers found to notify about expired support user.", "Support User Expiration")


    for user_info in expired_users:
        try:
            user = frappe.get_doc("User", user_info.name)
            user.enabled = 0
            user.save(ignore_permissions=True)

            frappe.db.commit()
            print(f"  - Disabled expired support user: {user.email}")

            if recipients:
                email_context = {
                    "support_user_name": user.full_name,
                    "support_user_email": user.email,
                    "disabled_at": now_datetime().strftime("%Y-%m-%d %H:%M:%S")
                }
                send_tenant_email(
                    recipients=recipients,
                    template="Support User Expired",
                    args=email_context,
                    now=True
                )
                print(f"  - Sent expiration notification to System Managers for {user.email}")

        except Exception as e:
            frappe.db.rollback()
            frappe.log_error(frappe.get_traceback(), f"Failed to disable expired support user {user_info.email}")

    print("Expired Support User Cleanup Job Complete.")

