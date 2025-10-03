import frappe
import os
import json
import stripe
import subprocess
import requests
import time
from datetime import datetime, timedelta
from frappe.utils import nowdate, add_days, getdate, add_months, add_years, now_datetime, get_datetime
from .paystack_controller import PaystackController

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

def drop_tenant_site(site_name):
    """
    Drops a tenant site and its database. This is a destructive, irreversible action.
    """
    logs = []
    def log_and_print(message):
        print(message)
        logs.append(str(message))

    log_and_print(f"--- Starting Site Deletion for {site_name} at {now_datetime()} ---")
    success = False

    try:
        bench_path = frappe.conf.get("bench_path")
        if not bench_path:
            raise frappe.ValidationError("`bench_path` not set in control plane site_config.json")
        log_and_print(f"DEBUG: Using bench path: {bench_path}")

        # Check if site exists before trying to drop it
        sites_dir = os.path.join(bench_path, "sites")
        log_and_print(f"DEBUG: Checking for site directory in: {sites_dir}")

        site_path = os.path.join(sites_dir, site_name)
        log_and_print(f"DEBUG: Full site path being checked: {site_path}")

        if not os.path.exists(site_path):
            log_and_print(f"WARNING: Site directory '{site_path}' does not exist. Nothing to do.")
            success = True
            return

        db_root_password = frappe.conf.get("db_root_password")

        log_and_print(f"\nStep 1: Preparing 'bench drop-site' command for '{site_name}'...")
        command = ["bench", "drop-site", site_name, "--force"]

        if db_root_password:
            log_and_print("Found db_root_password. Adding to command.")
            command.extend(["--mariadb-root-password", db_root_password])

        log_and_print(f"DEBUG: Executing command: {' '.join(command)}")
        process = subprocess.run(command, cwd=bench_path, capture_output=True, text=True, timeout=180)
        log_and_print(f"--- 'bench drop-site' STDOUT ---\n{process.stdout or 'No standard output.'}")
        log_and_print(f"--- 'bench drop-site' STDERR ---\n{process.stderr or 'No standard error.'}")

        # drop-site can return non-zero exit codes on warnings (e.g., if db doesn't exist)
        # We check for success by verifying the site directory is gone.
        if os.path.exists(site_path):
             # If the command had a non-zero return code and the site still exists, it's a failure.
            if process.returncode != 0:
                process.check_returncode() # This will raise CalledProcessError
            else:
                # This case is unlikely but indicates something went wrong.
                raise Exception(f"`bench drop-site` command completed with exit code 0, but the site directory '{site_path}' still exists.")

        log_and_print(f"SUCCESS: Site '{site_name}' and its database have been dropped.")

        # After successful deletion, update the subscription status
        try:
            subscription_name = frappe.db.get_value("Company Subscription", {"site_name": site_name}, "name")
            if subscription_name:
                subscription = frappe.get_doc("Company Subscription", subscription_name)
                subscription.status = "Dropped"
                subscription.save(ignore_permissions=True)
                frappe.db.commit()
                log_and_print(f"SUCCESS: Updated subscription '{subscription_name}' status to 'Dropped'.")
            else:
                log_and_print(f"INFO: No active subscription found for site '{site_name}'. No status to update.")
        except Exception as sub_e:
            # Log this as a non-fatal error. The site is already gone, which is the most critical part.
            log_and_print(f"WARNING: Site was dropped, but failed to update subscription status. Reason: {sub_e}")


        success = True

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, Exception) as e:
        error_message = f"STDOUT: {getattr(e, 'stdout', 'N/A')}\nSTDERR: {getattr(e, 'stderr', 'N/A')}\nTRACEBACK: {frappe.get_traceback()}"
        log_and_print(f"\n--- FATAL ERROR during site deletion ---\n{error_message}")
        # Mark as not successful, the finally block will handle notification
        success = False

    finally:
        _log_and_notify(site_name, logs, success, "Site Deletion")


def cleanup_unverified_tenants():
    """
    Finds and cancels subscriptions that have not been email-verified
    within a specific timeframe after their creation.
    """
    frappe.log("Running Cleanup for Unverified Tenants...")
    verification_period_days = 3
    cutoff_date = add_days(nowdate(), -verification_period_days)

    unverified_subscriptions = frappe.get_all(
        "Company Subscription",
        filters={
            "status": ["in", ["Active", "Trialing", "Provisioning"]],
            "email_verified_on": ("is", "not set"),
            "subscription_start_date": ("<=", cutoff_date)
        },
        fields=["name", "customer", "site_name", "subscription_start_date"]
    )

    if not unverified_subscriptions:
        frappe.log("No unverified subscriptions found that require cleanup. Exiting.")
        return

    frappe.log(f"Found {len(unverified_subscriptions)} unverified subscriptions to cancel.")

    for sub_data in unverified_subscriptions:
        try:
            subscription = frappe.get_doc("Company Subscription", sub_data.name)
            subscription.status = "Canceled"
            subscription.save(ignore_permissions=True)
            frappe.db.commit()

            log_message = (
                f"Canceled subscription {subscription.name} for customer '{sub_data.customer}' "
                f"(Site: {sub_data.site_name}) due to missing email verification. "
                f"Start date: {sub_data.subscription_start_date}."
            )
            frappe.log(log_message, title="Subscription Canceled (No Verification)")

        except Exception as e:
            error_message = (
                f"Failed to cancel unverified subscription {sub_data.name}. "
                f"Reason: {e}\n{frappe.get_traceback()}"
            )
            frappe.log_error(message=error_message, title="Subscription Cleanup Failed")

    frappe.log("--- Unverified Tenant Cleanup Complete ---")
def manage_daily_subscriptions():
    """
    Manages the daily lifecycle of all subscriptions.
    - Converts trials to active or downgrades them.
    - Moves active subscriptions with failed payments to a grace period.
    - Downgrades subscriptions after the grace period expires.
    """
    frappe.log("--- Running Daily Subscription Management ---", "Subscription Management")
    today = getdate(nowdate())

    # --- 1. Handle expiring trials ---
    expiring_trials = frappe.get_all(
        "Company Subscription",
        filters={"status": "Trialing", "trial_ends_on": ("<=", today)},
        fields=["name", "customer", "plan"]
    )
    frappe.log(f"Found {len(expiring_trials)} expiring trial subscriptions to process.", "Subscription Management")
    for sub_info in expiring_trials:
        try:
            subscription = frappe.get_doc("Company Subscription", sub_info.name)
            has_payment_method = frappe.db.get_value("Customer", sub_info.customer, "stripe_customer_id")

            if has_payment_method:
                # TODO: In the future, this is where payment would be attempted.
                # For now, we assume success and convert to Active.
                frappe.log(f"Subscription {sub_info.name}: Trial ended with payment method. Converting to Active.", "Subscription Management")
                subscription.status = "Active"
                plan = frappe.get_doc("Subscription Plan", sub_info.plan)
                if plan.billing_cycle == 'Month':
                    subscription.next_billing_date = add_months(today, 1)
                elif plan.billing_cycle == 'Year':
                    subscription.next_billing_date = add_years(today, 1)
                subscription.trial_ends_on = None
                subscription.save(ignore_permissions=True)
            else:
                # No payment method, so downgrade to the 'Free-Monthly' plan.
                frappe.log(f"Subscription {sub_info.name}: Trial ended without payment method. Downgrading to free plan.", "Subscription Management")
                subscription.previous_plan = subscription.plan
                subscription.status = "Downgraded"
                subscription.plan = 'Free-Monthly'
                subscription.trial_ends_on = None
                subscription.next_billing_date = None
                subscription.save(ignore_permissions=True)
            frappe.db.commit()
        except Exception as e:
            frappe.log_error(f"Failed to process trial expiration for {sub_info.name}: {e}", "Subscription Management Error")

    # --- 2. Handle auto-renewals for free plans ---
    free_renewal_filters = {
        "status": "Free",
        "next_billing_date": ("<=", today)
    }
    subscriptions_for_free_renewal = frappe.get_all(
        "Company Subscription",
        filters=free_renewal_filters,
        fields=["name", "plan"]
    )
    frappe.log(f"Found {len(subscriptions_for_free_renewal)} free subscriptions due for auto-renewal.", "Subscription Management")
    for sub_info in subscriptions_for_free_renewal:
        try:
            subscription = frappe.get_doc("Company Subscription", sub_info.name)
            plan = frappe.get_doc("Subscription Plan", sub_info.plan)

            if plan.billing_cycle == 'Month':
                subscription.next_billing_date = add_months(today, 1)
            elif plan.billing_cycle == 'Year':
                subscription.next_billing_date = add_years(today, 1)

            subscription.save(ignore_permissions=True)
            frappe.db.commit()
            frappe.log(f"Subscription {sub_info.name}: Auto-renewed free plan. New billing date: {subscription.next_billing_date}.", "Subscription Management")
        except Exception as e:
            frappe.log_error(f"Failed to auto-renew free subscription {sub_info.name}: {e}", "Subscription Management Error")


    # --- 3. Handle renewals / failed payments for active subscriptions ---
    # We explicitly exclude free plans from this logic.
    renewal_filters = {
        "status": "Active",
        "next_billing_date": ("<=", today),
    }
    # This is a bit more complex, so we get more fields.
    subscriptions_for_renewal = frappe.get_all(
        "Company Subscription",
        filters=renewal_filters,
        fields=["name", "customer", "plan"]
    )

    if subscriptions_for_renewal:
        paystack_controller = PaystackController()
        frappe.log(f"Found {len(subscriptions_for_renewal)} active subscriptions due for renewal.", "Subscription Management")

        for sub_info in subscriptions_for_renewal:
            try:
                subscription = frappe.get_doc("Company Subscription", sub_info.name)
                plan = frappe.get_doc("Subscription Plan", sub_info.plan)
                customer = frappe.get_doc("Customer", sub_info.customer)

                # Skip free plans in this loop.
                if plan.cost == 0:
                    continue

                frappe.log(f"Attempting renewal payment for subscription {subscription.name}...", "Subscription Management")
                payment_result = paystack_controller.charge_customer(
                    customer_email=customer.customer_primary_email,
                    amount_in_base_unit=plan.cost,
                    currency=plan.currency
                )

                if payment_result.get("success"):
                    # Payment was successful, extend the billing date.
                    if plan.billing_cycle == 'Month':
                        subscription.next_billing_date = add_months(today, 1)
                    elif plan.billing_cycle == 'Year':
                        subscription.next_billing_date = add_years(today, 1)
                    subscription.save(ignore_permissions=True)
                    frappe.db.commit()
                    frappe.log(f"SUCCESS: Subscription {subscription.name} renewed. Next billing date: {subscription.next_billing_date}", "Subscription Management")
                    # TODO: Enqueue a "successful payment" email notification.
                else:
                    # Payment failed, move to Grace Period.
                    frappe.log(f"FAILURE: Payment failed for subscription {subscription.name}. Reason: {payment_result.get('message')}. Moving to Grace Period.", "Subscription Management")
                    subscription.status = "Grace Period"
                    subscription.save(ignore_permissions=True)
                    frappe.db.commit()
                    # TODO: Enqueue a "payment failed" email notification.

            except Exception as e:
                frappe.log_error(f"Failed to process renewal for subscription {sub_info.name}: {e}", "Subscription Management Error")

    # --- 4. Handle expired grace periods ---
    grace_period_days = frappe.db.get_single_value("Subscription Settings", "grace_period_days") or 5
    subscriptions_in_grace = frappe.get_all(
        "Company Subscription",
        filters={"status": "Grace Period"},
        fields=["name", "plan", "next_billing_date"]
    )
    frappe.log(f"Found {len(subscriptions_in_grace)} subscriptions in grace period. Checking for expiry.", "Subscription Management")
    for sub_info in subscriptions_in_grace:
        try:
            grace_period_ends = add_days(getdate(sub_info.next_billing_date), grace_period_days)
            if today >= grace_period_ends:
                subscription = frappe.get_doc("Company Subscription", sub_info.name)
                frappe.log(f"Subscription {sub_info.name}: Grace period ended. Downgrading to free plan.", "Subscription Management")
                subscription.previous_plan = subscription.plan
                subscription.status = "Downgraded"
                subscription.plan = 'Free-Monthly'
                subscription.next_billing_date = None
                subscription.save(ignore_permissions=True)
                frappe.db.commit()
        except Exception as e:
            frappe.log_error(f"Failed to process grace period for {sub_info.name}: {e}", "Subscription Management Error")

    frappe.log("--- Daily Subscription Management Complete ---", "Subscription Management")
def _downgrade_subscription(subscription_info): pass
def _send_trial_ending_notification(subscription_info): pass
def cleanup_failed_provisions(): pass
def run_weekly_maintenance(): pass
def generate_subscription_invoices(): pass
def _charge_invoice(invoice, customer, settings): pass


def retry_payment_for_subscription_job(subscription_name, user):
    """
    A background job that attempts to charge a customer for a single subscription renewal.
    Notifies the calling user of the outcome.
    """
    try:
        subscription = frappe.get_doc("Company Subscription", subscription_name)
        plan = frappe.get_doc("Subscription Plan", subscription.plan)
        customer = frappe.get_doc("Customer", subscription.customer)

        if subscription.status != "Grace Period":
            frappe.publish_realtime("show_alert", {"message": f"Subscription {subscription.name} is not in a 'Grace Period' status.", "indicator": "orange"}, user=user)
            return

        paystack_controller = PaystackController()
        payment_result = paystack_controller.charge_customer(
            customer_email=customer.customer_primary_email,
            amount_in_base_unit=plan.cost,
            currency=plan.currency
        )

        if payment_result.get("success"):
            subscription.status = "Active"
            if plan.billing_cycle == 'Month':
                subscription.next_billing_date = add_months(getdate(nowdate()), 1)
            elif plan.billing_cycle == 'Year':
                subscription.next_billing_date = add_years(getdate(nowdate()), 1)
            subscription.save(ignore_permissions=True)
            frappe.db.commit()
            frappe.publish_realtime("show_alert", {"message": f"Payment for {subscription.name} was successful. Status is now 'Active'.", "indicator": "green"}, user=user)
        else:
            # Payment failed again. Notify the user.
            frappe.publish_realtime("show_alert", {"message": f"Payment for {subscription.name} failed again. Reason: {payment_result.get('message')}", "indicator": "red"}, user=user)

    except Exception as e:
        frappe.log_error(f"Failed to retry payment for subscription {subscription_name}: {e}", "Subscription Payment Retry Error")
        frappe.publish_realtime("show_alert", {"message": f"An unexpected error occurred while retrying payment for {subscription_name}. See the Error Log for details.", "indicator": "red"}, user=user)


def delete_customer_data(customer_name):
    """
    Background job to delete all data associated with a customer.
    Currently, this deletes all Company Subscriptions for the customer.
    """
    logs = [f"--- Starting Data Deletion for Customer {customer_name} at {now_datetime()} ---"]
    success = False
    try:
        subscriptions = frappe.get_all("Company Subscription", filters={"customer": customer_name})
        if not subscriptions:
            logs.append(f"No subscriptions found for customer {customer_name}. Nothing to do.")
            success = True
            return

        logs.append(f"Found {len(subscriptions)} subscriptions to delete.")
        for sub in subscriptions:
            # Using delete_doc will trigger the 'on_trash' hook for Company Subscription,
            # which in turn enqueues the site deletion job.
            frappe.delete_doc(
                "Company Subscription",
                sub.name,
                ignore_permissions=True,
                delete_permanently=True
            )
            logs.append(f"Deleted Company Subscription: {sub.name}")

        logs.append(f"Successfully deleted all data for customer {customer_name}.")
        success = True

    except Exception as e:
        logs.append(f"\n--- FATAL ERROR during customer data deletion ---\n{frappe.get_traceback()}")
        success = False
    finally:
        # Using a different subject prefix to distinguish from other operational emails.
        _log_and_notify(customer_name, logs, success, "Customer Data Deletion")