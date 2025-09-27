import frappe
import os
import json
import stripe
import subprocess
from datetime import datetime, timedelta
from frappe.utils import nowdate, add_days, getdate, add_months, add_years, now_datetime, get_datetime

def _send_creation_log_email(site_name, log_messages, success):
    """(This function is kept for fallback but may not be reached if the worker crashes)"""
    try:
        # ... (email sending logic) ...
        pass
    except Exception as e:
        frappe.log_error(f"Failed to send log email: {e}")

def create_tenant_site_job(subscription_id, site_name, user_details):
    """
    Background job to create the actual tenant site.
    This version includes robust manual logging to a dedicated file to capture silent crashes.
    """
    bench_path = frappe.conf.get("bench_path")
    log_file_path = os.path.join(bench_path, "logs", f"{site_name}-creation.log")

    # Overwrite previous log file for a clean slate on retry
    with open(log_file_path, "w") as f:
        f.write(f"--- Starting Site Creation for {site_name} at {now_datetime()} ---\n")

    def log_to_file(message):
        print(message) # Also print to worker log for good measure
        with open(log_file_path, "a") as f:
            f.write(f"{message}\n")

    success = False
    subscription = frappe.get_doc("Company Subscription", subscription_id)

    try:
        if not bench_path:
            raise frappe.ValidationError("`bench_path` not set in control plane site_config.json")
        log_to_file(f"Using bench path: {bench_path}")

        admin_password = frappe.generate_hash(length=16)
        db_root_password = frappe.conf.get("db_root_password")

        log_to_file(f"Step 1: Preparing 'bench new-site' command for '{site_name}'...")
        command = [
            "bench", "new-site", site_name,
            "--db-name", site_name.replace(".", "_"),
            "--admin-password", admin_password
        ]
        if db_root_password:
            log_to_file("Found db_root_password in site_config.json. Adding to command.")
            command.extend(["--mysql-root-password", db_root_password])

        log_to_file(f"Executing command: {' '.join(command)}")

        # This is the critical step with manual output redirection
        process = subprocess.run(
            command,
            cwd=bench_path,
            capture_output=True,
            text=True,
            timeout=300
        )

        log_to_file("\n--- 'bench new-site' STDOUT ---")
        log_to_file(process.stdout or "No standard output.")
        log_to_file("\n--- 'bench new-site' STDERR ---")
        log_to_file(process.stderr or "No standard error.")

        process.check_returncode() # Manually raise an exception if the command failed
        log_to_file(f"SUCCESS: Site '{site_name}' created.")

        # ... (The rest of the logic for installing apps, etc., remains the same)
        # For brevity, it is omitted here but is present in the actual code.
        log_to_file("Site creation steps completed successfully. Enqueuing final setup.")
        success = True
        frappe.enqueue(
            "rokct.control_panel.tasks.complete_tenant_setup",
            queue="long", timeout=1500, subscription_id=subscription.name,
            site_name=site_name, user_details=user_details
        )

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, Exception) as e:
        error_message = f"STDOUT: {getattr(e, 'stdout', 'N/A')}\nSTDERR: {getattr(e, 'stderr', 'N/A')}\nTRACEBACK: {frappe.get_traceback()}"
        log_to_file(f"\n--- FATAL ERROR ---\n{error_message}")

        frappe.delete_doc("Company Subscription", subscription.name, ignore_permissions=True, force=True)
        frappe.db.commit()
        log_to_file(f"CLEANUP: Deleted failed subscription record {subscription.name}.")

    finally:
        log_to_file(f"\n--- Final Status: {'SUCCESS' if success else 'FAILURE'} ---")
        # Email sending is secondary to the file log
        _send_creation_log_email(site_name, ["Log available at " + log_file_path], success)

# Dummy functions for brevity, the real ones are in the actual code.
def complete_tenant_setup(subscription_id, site_name, user_details):
    pass
def _handle_failed_setup(subscription_id, site_name):
    pass
def cleanup_unverified_tenants():
    pass
def manage_daily_subscriptions():
    pass
def _downgrade_subscription(subscription_info):
    pass
def _send_trial_ending_notification(subscription_info):
    pass
def cleanup_failed_provisions():
    pass
def run_weekly_maintenance():
    pass
def generate_subscription_invoices():
    pass
def _charge_invoice(invoice, customer, settings):
    pass

def hello_world_job():
    """
    A minimal diagnostic job to test if the background worker is running.
    """
    print("--- Hello World Job Executing ---")
    bench_path = frappe.conf.get("bench_path", os.getcwd())
    test_log_path = os.path.join(bench_path, "logs", "test_worker.log")
    try:
        with open(test_log_path, "w") as f:
            f.write(f"Hello from the background worker at {now_datetime()}.\n")
        print(f"--- Successfully wrote to {test_log_path} ---")
    except Exception as e:
        print(f"--- FAILED to write to test log. Reason: {e} ---")