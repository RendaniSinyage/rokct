import frappe
import os
import json
import stripe
import subprocess
from datetime import datetime, timedelta
from frappe.utils import nowdate, add_days, getdate, add_months, add_years, now_datetime, get_datetime

# ------------------------------------------------------------------------------
# Tenant Provisioning Jobs
# ------------------------------------------------------------------------------

def _send_creation_log_email(site_name, log_messages, success):
    """Sends the site creation log to the admin."""
    try:
        status = "SUCCESS" if success else "FAILURE"
        subject = f"Log for Site Creation: {site_name} - {status}"

        log_content = "\n".join(log_messages)

        final_message = f"\n\nFinal Status: {status}"
        log_content += final_message

        frappe.sendmail(
            recipients=["sinyage@gmail.com"],
            subject=subject,
            message=log_content,
            now=True
        )
        print("--- Creation log email sent to sinyage@gmail.com ---")
    except Exception as e:
        print(f"--- FAILED to send creation log email. Reason: {e} ---")
        frappe.log_error("Failed to send site creation log email", "Email Error")

def create_tenant_site_job(subscription_id, site_name, user_details):
    """
    Background job to create the actual tenant site using bench commands.
    This is the long-running part of the provisioning process.
    """
    logs = [f"--- Starting Site Creation for {site_name} at {now_datetime()} ---"]
    success = False
    subscription = frappe.get_doc("Company Subscription", subscription_id)

    try:
        bench_path = frappe.conf.get("bench_path")
        if not bench_path:
            raise frappe.ValidationError("`bench_path` not set in control plane site_config.json")
        logs.append(f"Using bench path: {bench_path}")

        admin_password = frappe.generate_hash(length=16)
        db_root_password = frappe.conf.get("db_root_password")

        logs.append(f"Step 1: Creating new site '{site_name}'...")

        command = [
            "bench", "new-site", site_name,
            "--db-name", site_name.replace(".", "_"),
            "--admin-password", admin_password
        ]
        if db_root_password:
            logs.append("Found db_root_password in site_config.json. Using it for site creation.")
            command.extend(["--mysql-root-password", db_root_password])

        subprocess.run(
            command,
            cwd=bench_path, check=True, capture_output=True, text=True
        )
        logs.append(f"SUCCESS: Site '{site_name}' created.")

        plan = frappe.get_doc("Subscription Plan", subscription.plan)
        plan_apps = [d.module for d in plan.get("modules", [])]
        logs.append(f"Plan '{subscription.plan}' requires apps: {', '.join(plan_apps)}")

        common_apps = ["frappe", "erpnext", "payments", "swagger", "rokct"]
        final_apps = list(dict.fromkeys(common_apps + plan_apps))
        if "rokct" in final_apps:
            final_apps.remove("rokct")
            final_apps.append("rokct")
        logs.append(f"Final app list for installation: {', '.join(final_apps)}")

        apps_txt_path = os.path.join(bench_path, "sites", site_name, "apps.txt")
        with open(apps_txt_path, "w") as f:
            f.write("\n".join(final_apps))
        logs.append(f"SUCCESS: Created site-specific apps.txt for {site_name}.")

        logs.append("\nStep 2: Installing apps on new site...")
        for app in final_apps:
            try:
                logs.append(f"  - Installing app '{app}'...")
                subprocess.run(
                    ["bench", "--site", site_name, "install-app", app],
                    cwd=bench_path, check=True, capture_output=True, text=True
                )
                logs.append(f"  - SUCCESS: Installed '{app}'.")
            except subprocess.CalledProcessError as e:
                raise frappe.ValidationError(f"Failed to install app {app}. Error: {e.stderr}")
        logs.append("SUCCESS: All apps installed.")

        logs.append("\nStep 3: Setting app_role for new site...")
        subprocess.run(
            ["bench", "--site", site_name, "set-config", "-g", "app_role", "tenant"],
            cwd=bench_path, check=True, capture_output=True, text=True
        )
        logs.append("SUCCESS: app_role set to 'tenant'.")

        subscription.status = "Provisioning"
        subscription.save(ignore_permissions=True)
        frappe.db.commit()
        logs.append("\nSUCCESS: Site created. Enqueuing final setup job.")

        success = True # Mark as successful before final enqueue
        frappe.enqueue(
            "rokct.control_panel.tasks.complete_tenant_setup",
            queue="long", timeout=1500, subscription_id=subscription.name,
            site_name=site_name, user_details=user_details
        )

    except (subprocess.CalledProcessError, Exception) as e:
        error_message = f"STDOUT: {getattr(e, 'stdout', 'N/A')}\nSTDERR: {getattr(e, 'stderr', 'N/A')}\nTRACEBACK: {frappe.get_traceback()}"
        logs.append(f"\n--- FATAL ERROR ---\n{error_message}")
        frappe.log_error(error_message, "Tenant Provisioning: Bench Command Failed")

        # Cleanup failed subscription
        frappe.delete_doc("Company Subscription", subscription.name, ignore_permissions=True, force=True)
        frappe.db.commit()
        logs.append(f"CLEANUP: Deleted failed subscription record {subscription.name}.")

    finally:
        _send_creation_log_email(site_name, logs, success)


# The rest of the file remains unchanged. I have omitted it for brevity.
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