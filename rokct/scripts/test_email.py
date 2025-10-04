# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe

def send_test_email():
    """
    A simple, direct script to test the email sending functionality.
    This bypasses the background workers to provide a clear, immediate error message.
    """
    print("--- Starting Email Diagnostic Test ---")

    recipient = "sinyage@gmail.com"
    subject = "Frappe Email Diagnostic Test"
    message = "This is a test email sent directly from a Frappe bench command. If you are seeing this, frappe.sendmail is working."

    try:
        print(f"Attempting to send test email to: {recipient}")
        frappe.sendmail(
            recipients=[recipient],
            subject=subject,
            message=message,
            now=True
        )
        print("\n--- SUCCESS ---")
        print("The `frappe.sendmail` command executed without an error.")
        print("Please check the inbox for sinyage@gmail.com (and the spam folder).")
        print("If the email is still not received, the issue is likely with your server's outgoing mail configuration (e.g., Postfix, SMTP settings in site_config.json).")

    except Exception as e:
        print("\n--- FATAL ERROR ---")
        print("The `frappe.sendmail` command failed. This is the root cause of the missing emails.")
        print("Please provide the following full error traceback to your system administrator to fix the mail server configuration:")
        print("--------------------------------------------------")
        # frappe.log_error provides a full traceback in the error log
        frappe.log_error(message=frappe.get_traceback(), title="Email Diagnostic Test Failed")
        # Also print it directly to the console
        import traceback
        traceback.print_exc()
        print("--------------------------------------------------")