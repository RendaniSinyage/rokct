# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe

def send_tenant_email(**kwargs):
    """
    A centralized utility for sending emails from a tenant site.
    It checks for and uses custom SMTP settings if they are configured and enabled.
    Otherwise, it falls back to the system's default Email Account.
    """
    try:
        settings = frappe.get_doc("Tenant Email Settings")
        if settings.enable_custom_smtp and settings.smtp_server and settings.username and settings.password:
            # Use the custom SMTP provider
            frappe.sendmail(
                **kwargs,
                smtp_server=settings.smtp_server,
                smtp_port=settings.smtp_port,
                use_tls=settings.use_tls,
                username=settings.username,
                password=settings.get_password("password")
            )
            return
    except Exception as e:
        # Log the error but proceed to fallback
        frappe.log_error(f"Failed to send email using custom SMTP settings: {e}", "Custom SMTP Error")

    # Fallback to default system email account
    frappe.sendmail(**kwargs)

