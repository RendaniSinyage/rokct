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
            cwd=bench_path, check=True, capture_output=True, text=True, timeout=300
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


def complete_tenant_setup(subscription_id, site_name, user_details):
    """
    A background job with retries to complete the setup of a new tenant site
    by calling the site's initial_setup API.
    """
    import time
    import json

    max_retries = 5
    retry_delay = 30  # seconds

    for i in range(max_retries):
        try:
            print(f"Attempt {i+1} to setup site {site_name}...")

            subscription = frappe.get_doc("Company Subscription", subscription_id)
            api_secret = frappe.utils.get_password(doctype="Company Subscription", name=subscription.name, fieldname="api_secret")

            # Determine the correct login redirect URL using 3-tiered fallback
            login_redirect_url = (
                subscription.custom_login_redirect_url
                or frappe.db.get_single_value("Subscription Settings", "marketing_site_login_url")
                or frappe.db.get_single_value("Subscription Settings", "default_login_redirect_url")
            )

            scheme = frappe.conf.get("tenant_site_scheme", "http")
            tenant_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.initial_setup"

            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {api_secret}"
            }

            data = {
                "email": user_details["email"],
                "password": user_details["password"],
                "first_name": user_details["first_name"],
                "last_name": user_details["last_name"],
                "company_name": user_details["company_name"],
                "currency": user_details["currency"],
                "country": user_details["country"],
                "verification_token": user_details["verification_token"],
                "api_secret": api_secret,
                "control_plane_url": frappe.utils.get_url(),
                "login_redirect_url": login_redirect_url
            }

            response = frappe.make_post_request(tenant_url, headers=headers, data=json.dumps(data))

            if response.get("status") == "success":
                print(f"Successfully completed setup for site {site_name}")
                # Set the subscription to Active/Trialing/Free now that setup is complete
                plan = frappe.get_doc("Subscription Plan", subscription.plan)
                if plan.cost == 0:
                    subscription.status = "Free"
                elif plan.trial_period_days > 0:
                    subscription.status = "Trialing"
                else:
                    subscription.status = "Active"
                subscription.save(ignore_permissions=True)
                frappe.db.commit()

                # Send welcome email from the control panel
                scheme = frappe.conf.get("tenant_site_scheme", "http")
                verification_url = f"{scheme}://{site_name}/api/method/rokct.tenant.api.verify_my_email?token={user_details['verification_token']}"
                email_context = {
                    "first_name": user_details["first_name"],
                    "company_name": user_details["company_name"],
                    "verification_url": verification_url
                }
                frappe.sendmail(
                    recipients=[user_details["email"]],
                    template="New User Welcome",
                    args=email_context,
                    now=True
                )
                return # Exit successfully

            else:
                # If there was a validation error on the tenant side, log it and retry
                frappe.log_error(f"Tenant setup for {site_name} failed with message: {response.get('message')}", "Tenant Setup Retryable Error")

        except Exception as e:
            # This catches connection errors, timeouts, etc.
            frappe.log_error(frappe.get_traceback(), f"Tenant Setup Call Failed for {site_name} on attempt {i+1}")

        # If we reach here, it means the attempt failed. Wait before retrying.
        print(f"Setup for {site_name} failed on attempt {i+1}. Retrying in {retry_delay} seconds...")
        time.sleep(retry_delay)

    # If the loop finishes without returning, it means all retries have failed.
    _handle_failed_setup(subscription_id, site_name)


def _handle_failed_setup(subscription_id, site_name):
    """
    Handles the case where the tenant setup has failed after all retries.
    """
    tb = frappe.get_traceback()
    frappe.log_error(tb, f"CRITICAL: All attempts to setup tenant {site_name} have failed.")

    subscription = frappe.get_doc("Company Subscription", subscription_id)
    subscription.status = "Setup Failed"
    subscription.save(ignore_permissions=True)
    frappe.db.commit()

    # Send an email to the system administrator
    admin_email = frappe.get_value("User", "Administrator", "email")
    if admin_email:
        frappe.sendmail(
            recipients=[admin_email],
            template="Critical Tenant Setup Failed",
            args={
                "site_name": site_name,
                "subscription_name": subscription.name,
                "customer": subscription.customer
            },
            now=True
        )

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