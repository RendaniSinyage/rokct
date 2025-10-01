import frappe
import os
import json
import stripe
import subprocess
import requests
import time
from datetime import datetime, timedelta
from frappe.utils import nowdate, add_days, getdate, add_months, add_years, now_datetime, get_datetime

def _log_and_notify(site_name, log_messages, success, subject_prefix):
    status = "SUCCESS" if success else "FAILURE"
    subject = f"{subject_prefix} for {site_name}: {status}"
    log_content = "\n".join(log_messages)

    if not success:
        frappe.log_error(message=log_content, title=subject)

    try:
        admin_email = frappe.db.get_single_value("System Settings", "email")
        if not admin_email:
            print("--- No admin email configured in System Settings. Skipping email notification. ---")
            return

        frappe.sendmail(
            recipients=[admin_email],
            subject=subject,
            message=log_content,
            now=True
        )
        print(f"--- {subject_prefix} notification email sent to {admin_email} ---")
    except Exception as e:
        print(f"--- FAILED to send {subject_prefix} notification email. Reason: {e} ---")
        frappe.log_error(f"Failed to send {subject_prefix} notification email for site {site_name}", "Email Error")

def create_tenant_site_job(subscription_id, site_name, user_details, synchronous=False):
    """
    Creates the tenant site, installs apps, and sets initial config.
    If `synchronous` is True, it will not enqueue the final setup job,
    allowing the caller to run it directly for debugging.
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

        logs.append(f"\nStep 1: Preparing 'bench new-site' command for '{site_name}'...")
        command = ["bench", "new-site", site_name, "--db-name", site_name.replace(".", "_"), "--admin-password", admin_password]
        if db_root_password:
            logs.append("Found db_root_password. Adding to command.")
            command.extend(["--mariadb-root-password", db_root_password])

        process = subprocess.run(command, cwd=bench_path, capture_output=True, text=True, timeout=300)
        logs.append(f"--- 'bench new-site' STDOUT ---\n{process.stdout or 'No standard output.'}")
        logs.append(f"--- 'bench new-site' STDERR ---\n{process.stderr or 'No standard error.'}")
        process.check_returncode()
        logs.append(f"SUCCESS: Site '{site_name}' created.")

        plan = frappe.get_doc("Subscription Plan", subscription.plan)
        if not plan:
            raise frappe.ValidationError(f"FATAL: Subscription Plan '{subscription.plan}' not found.")

        plan_modules = plan.get("modules") or []
        plan_apps = [d.module for d in plan_modules]
        common_apps = ["frappe", "erpnext", "payments", "swagger", "rokct"]
        final_apps = list(dict.fromkeys(common_apps + plan_apps))
        if "rokct" in final_apps:
            final_apps.remove("rokct")
            final_apps.append("rokct")

        apps_txt_path = os.path.join(bench_path, "sites", site_name, "apps.txt")
        with open(apps_txt_path, "w") as f:
            f.write("\n".join(final_apps))
        logs.append(f"SUCCESS: Created site-specific apps.txt.")

        logs.append("\nStep 2: Installing apps...")
        for app in final_apps:
            logs.append(f"  - Installing '{app}'...")
            subprocess.run(["bench", "--site", site_name, "install-app", app], cwd=bench_path, check=True, capture_output=True, text=True)
            logs.append(f"  - SUCCESS: Installed '{app}'.")

        logs.append("\nStep 3: Setting app_role...")
        subprocess.run(["bench", "--site", site_name, "set-config", "app_role", "tenant"], cwd=bench_path, check=True, capture_output=True, text=True)
        logs.append("SUCCESS: app_role set to 'tenant'.")

        subscription.status = "Provisioning"
        subscription.save(ignore_permissions=True)
        frappe.db.commit()
        logs.append("\nSUCCESS: Site created. Enqueuing final setup job.")

        success = True
        if not synchronous:
            frappe.enqueue("rokct.rokct.control_panel.tasks.complete_tenant_setup", queue="long", timeout=1500, subscription_id=subscription.name, site_name=site_name, user_details=user_details)
            logs.append("\nSUCCESS: Site created. Enqueued final setup job.")
        else:
            logs.append("\nSUCCESS: Site created. Skipping enqueue for synchronous execution.")

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, Exception) as e:
        error_message = f"STDOUT: {getattr(e, 'stdout', 'N/A')}\nSTDERR: {getattr(e, 'stderr', 'N/A')}\nTRACEBACK: {frappe.get_traceback()}"
        logs.append(f"\n--- FATAL ERROR ---\n{error_message}")
        frappe.delete_doc("Company Subscription", subscription.name, ignore_permissions=True, force=True)
        frappe.db.commit()
        logs.append(f"CLEANUP: Deleted failed subscription record {subscription.name}.")

    finally:
        _log_and_notify(site_name, logs, success, "Site Creation")

def complete_tenant_setup(subscription_id, site_name, user_details):
    logs = []
    def log_and_print(message):
        print(message)
        logs.append(str(message))

    log_and_print(f"--- Starting Final Tenant Setup for {site_name} at {now_datetime()} ---")
    success = False
    max_retries = 5
    retry_delay = 30

    for i in range(max_retries):
        log_and_print(f"\n--- Attempt {i+1} of {max_retries} ---")
        try:
            bench_path = frappe.conf.get("bench_path")
            if not bench_path:
                raise frappe.ValidationError("`bench_path` not set in control plane site_config.json")

            subscription = frappe.get_doc("Company Subscription", subscription_id)
            api_secret = subscription.get_password("api_secret")
            login_redirect_url = (subscription.custom_login_redirect_url or frappe.db.get_single_value("Subscription Settings", "marketing_site_login_url") or frappe.db.get_single_value("Subscription Settings", "default_login_redirect_url"))

            # Prepare kwargs for the `bench execute` command
            expected_keys = [
                "email", "password", "first_name", "last_name", "company_name",
                "currency", "country", "verification_token"
            ]
            kwargs = {k: v for k, v in user_details.items() if k in expected_keys}
            kwargs.update({
                "api_secret": api_secret,
                "control_plane_url": frappe.utils.get_url(),
                "login_redirect_url": login_redirect_url
            })

            command = [
                "bench", "--site", site_name, "execute",
                "rokct.rokct.tenant.api.initial_setup",
                "--kwargs", json.dumps(kwargs)
            ]
            log_and_print(f"Executing command: {' '.join(command)}")

            # Execute the setup function directly on the tenant site, bypassing the web server
            process = subprocess.run(command, cwd=bench_path, capture_output=True, text=True, check=True, timeout=180)
            log_and_print(f"--- 'bench execute' STDOUT ---\n{process.stdout or 'No standard output.'}")
            log_and_print(f"--- 'bench execute' STDERR ---\n{process.stderr or 'No standard error.'}")

            # The result from `bench execute` is printed to stdout. Parse it as JSON.
            response_json = json.loads(process.stdout) if process.stdout else {}
            status = response_json.get("status")

            if status in ["success", "warning"]:
                if status == "success":
                    log_and_print("SUCCESS: Tenant setup function executed successfully.")
                else:
                    log_and_print(f"NOTE: Tenant setup function returned a warning: {response_json.get('message')}. This is expected on retry.")

                plan = frappe.get_doc("Subscription Plan", subscription.plan)
                if plan.cost == 0:
                    subscription.status = "Free"
                elif plan.trial_period_days > 0:
                    subscription.status = "Trialing"
                else:
                    subscription.status = "Active"
                subscription.save(ignore_permissions=True)
                frappe.db.commit()
                log_and_print(f"Subscription status updated to '{subscription.status}'.")

                # Send welcome email from the control plane, as requested.
                scheme = frappe.conf.get("tenant_site_scheme", "http")
                verification_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.verify_my_email?token={user_details['verification_token']}"
                email_context = {
                    "first_name": user_details["first_name"],
                    "company_name": user_details["company_name"],
                    "verification_url": verification_url
                }

                try:
                    log_and_print(f"Attempting to send welcome email to {user_details['email']}...")
                    frappe.sendmail(recipients=[user_details["email"]], template_name="New User Welcome", args=email_context, now=True)
                    log_and_print("SUCCESS: Welcome email sent.")
                except Exception as e:
                    log_and_print(f"WARNING: Could not send welcome email. Reason: {e}")

                success = True
                return
            else:
                message = response_json.get('message') if isinstance(response_json, dict) else str(response_json)
                log_and_print(f"WARNING: Tenant setup function failed with message: {message}")

        except subprocess.CalledProcessError as e:
            log_and_print(f"CRITICAL: The 'bench execute' command failed.")
            log_and_print(f"STDOUT: {e.stdout}")
            log_and_print(f"STDERR: {e.stderr}")
        except Exception as e:
            log_and_print(f"CRITICAL: An unexpected error occurred. Reason: {e}")
            log_and_print(f"TRACEBACK: {frappe.get_traceback()}")

        log_and_print(f"Retrying in {retry_delay} seconds...")
        time.sleep(retry_delay)

    _handle_failed_setup(subscription_id, site_name, logs)

def _handle_failed_setup(subscription_id, site_name, logs):
    logs.append("\n--- CRITICAL: All attempts to setup tenant have failed. ---")

    subscription = frappe.get_doc("Company Subscription", subscription_id)
    subscription.status = "Setup Failed"
    subscription.save(ignore_permissions=True)
    frappe.db.commit()
    logs.append(f"Subscription status set to 'Setup Failed'.")

    _log_and_notify(site_name, logs, False, "Critical Tenant Setup Failure")

def cleanup_unverified_tenants(): pass
def manage_daily_subscriptions(): pass
def _downgrade_subscription(subscription_info): pass
def _send_trial_ending_notification(subscription_info): pass
def cleanup_failed_provisions(): pass
def run_weekly_maintenance(): pass
def generate_subscription_invoices(): pass
def _charge_invoice(invoice, customer, settings): pass

def drop_tenant_site(site_name, force=True):
    """
    Drops a tenant site from the bench. This is a destructive action.
    """
    import subprocess
    logs = [f"--- Starting Drop Site for {site_name} at {now_datetime()} ---"]
    success = False

    try:
        bench_path = frappe.conf.get("bench_path")
        if not bench_path:
            raise frappe.ValidationError("`bench_path` not set in control plane site_config.json")
        logs.append(f"Using bench path: {bench_path}")

        db_root_password = frappe.conf.get("db_root_password")
        if not db_root_password:
            raise frappe.ValidationError("`db_root_password` not set in control plane site_config.json. Cannot drop site.")

        command = [
            "bench", "drop-site", site_name,
            "--db-root-password", db_root_password,
        ]
        if force:
            command.append("--force")

        logs.append(f"Executing command: {' '.join(command)}")
        process = subprocess.run(command, cwd=bench_path, capture_output=True, text=True, timeout=300)
        logs.append(f"--- 'bench drop-site' STDOUT ---\n{process.stdout or 'No standard output.'}")
        logs.append(f"--- 'bench drop-site' STDERR ---\n{process.stderr or 'No standard error.'}")
        process.check_returncode()
        logs.append(f"SUCCESS: Site '{site_name}' dropped.")
        success = True

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, Exception) as e:
        error_message = f"STDOUT: {getattr(e, 'stdout', 'N/A')}\nSTDERR: {getattr(e, 'stderr', 'N/A')}\nTRACEBACK: {frappe.get_traceback()}"
        logs.append(f"\n--- FATAL ERROR during site drop ---\n{error_message}")

    finally:
        _log_and_notify(site_name, logs, success, "Site Deletion")