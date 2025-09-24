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

def create_tenant_site_job(subscription_id, site_name, user_details):
    """
    Background job to create the actual tenant site using bench commands.
    This is the long-running part of the provisioning process.
    """
    subscription = frappe.get_doc("Company Subscription", subscription_id)
    try:
        bench_path = frappe.conf.get("bench_path")
        if not bench_path:
            raise frappe.ValidationError("`bench_path` not set in control plane site_config.json")

        # Generate a secure, random password for the new site's administrator
        # This is temporary and will be overwritten by the user's password during setup.
        admin_password = frappe.generate_hash(length=16)

        # Create new site without installing any apps initially
        frappe.log_error(f"Creating new site {site_name}...", "Tenant Provisioning")
        subprocess.run(
            [
                "bench", "new-site", site_name,
                "--db-name", site_name.replace(".", "_"),
                "--admin-password", admin_password
            ],
            cwd=bench_path,
            check=True,
            capture_output=True,
            text=True
        )

        # Get the subscription plan to determine which apps to install
        plan = frappe.get_doc("Subscription Plan", subscription.plan)
        plan_apps = [d.module for d in plan.get("modules", [])]

        # Define common apps that are always installed
        common_apps = ["frappe", "erpnext", "payments", "swagger", "rokct"]

        # Combine and order the apps, ensuring rokct is last
        final_apps = list(dict.fromkeys(common_apps + plan_apps))
        if "rokct" in final_apps:
            final_apps.remove("rokct")
            final_apps.append("rokct")

        # Create the site-specific apps.txt
        apps_txt_path = os.path.join(bench_path, "sites", site_name, "apps.txt")
        with open(apps_txt_path, "w") as f:
            f.write("\n".join(final_apps))
        print(f"Successfully created site-specific apps.txt for {site_name}.")

        # Install all the required apps on the new site
        for app in final_apps:
            try:
                print(f"Installing app '{app}' on site '{site_name}'...")
                subprocess.run(
                    ["bench", "--site", site_name, "install-app", app],
                    cwd=bench_path, check=True, capture_output=True, text=True
                )
            except subprocess.CalledProcessError as e:
                raise frappe.ValidationError(f"Failed to install app {app} on {site_name}. Error: {e.stderr}")

        # Set app_role in site_config.json
        frappe.log_error(f"Setting app_role for {site_name}...", "Tenant Provisioning")
        subprocess.run(
            ["bench", "--site", site_name, "set-config", "-g", "app_role", "tenant"],
            cwd=bench_path,
            check=True,
            capture_output=True,
            text=True
        )

        # If site creation is successful, update subscription status and enqueue the next step
        subscription.status = "Provisioning"
        subscription.save(ignore_permissions=True)
        frappe.db.commit()

        frappe.enqueue(
            "rokct.control_panel.tasks.complete_tenant_setup",
            queue="long",
            timeout=1500,
            subscription_id=subscription.name,
            site_name=site_name,
            user_details=user_details
        )
        frappe.log_error(f"Successfully created site {site_name}. Enqueued final setup.", "Tenant Provisioning")

    except subprocess.CalledProcessError as e:
        # Cleanup subscription record if site creation fails
        frappe.delete_doc("Company Subscription", subscription.name, ignore_permissions=True)
        frappe.db.commit()

        error_message = f"STDOUT: {e.stdout}\nSTDERR: {e.stderr}"
        frappe.log_error(error_message, "Tenant Provisioning: Bench Command Failed")

        # Also notify the admin
        admin_email = frappe.get_value("User", "Administrator", "email")
        if admin_email:
            frappe.sendmail(
                recipients=[admin_email],
                template="Critical Tenant Creation Failed",
                args={
                    "site_name": site_name,
                    "error_message": error_message
                },
                now=True
            )

    except Exception as e:
        frappe.delete_doc("Company Subscription", subscription.name, ignore_permissions=True)
        frappe.db.commit()
        frappe.log_error(frappe.get_traceback(), "Tenant Provisioning: Unhandled Exception")


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
                # Set the subscription to Active/Trialing now that setup is complete
                plan = frappe.get_doc("Subscription Plan", subscription.plan)
                subscription.status = "Trialing" if not plan.is_free_plan and plan.trial_period_days else "Active"
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

# ------------------------------------------------------------------------------
# Daily Job
# ------------------------------------------------------------------------------

def cleanup_unverified_tenants():
    """
    Finds and deletes tenant sites that were created more than 7 days ago
    but whose owner has not verified their email address.
    """
    print("Running Daily Unverified Tenant Cleanup Job...")

    # Calculate the cutoff date (7 days ago)
    cutoff_date = now_datetime() - timedelta(days=7)

    # Find subscriptions that are older than the cutoff and still unverified
    unverified_subscriptions = frappe.get_all("Company Subscription",
        filters={
            "creation": ["<", cutoff_date],
            "email_verified_on": ["is", "null"]
        },
        fields=["name", "site_name", "customer"]
    )

    if not unverified_subscriptions:
        print("No unverified tenants to clean up.")
        return

    print(f"Found {len(unverified_subscriptions)} unverified tenants to clean up...")
    bench_path = frappe.conf.get("bench_path")

    for sub in unverified_subscriptions:
        site_name = sub.get("site_name")
        print(f"  - Processing subscription {sub.name} for site {site_name}...")

        if not bench_path:
            frappe.log_error("`bench_path` not set in site_config.json. Cannot drop site.", "Tenant Cleanup Failed")
            continue

        try:
            # Drop the site and its database
            drop_command = ["bench", "drop-site", site_name, "--drop-db", "--force"]
            subprocess.run(drop_command, cwd=bench_path, check=True, capture_output=True, text=True)
            print(f"    - Successfully dropped site {site_name}.")

            # Delete the related documents on the control panel
            frappe.delete_doc("Company Subscription", sub.name, ignore_permissions=True, force=True)
            frappe.delete_doc("Customer", sub.customer, ignore_permissions=True, force=True)
            print(f"    - Successfully deleted subscription and customer records.")

            frappe.db.commit()

        except subprocess.CalledProcessError as e:
            frappe.db.rollback()
            error_message = f"STDOUT: {e.stdout}\nSTDERR: {e.stderr}"
            frappe.log_error(error_message, f"Tenant Cleanup: Bench Command Failed for {site_name}")
        except Exception as e:
            frappe.db.rollback()
            frappe.log_error(frappe.get_traceback(), f"Tenant Cleanup: Failed to process {sub.name}")

    print("Unverified Tenant Cleanup Job Complete.")


def manage_daily_subscriptions():
    """
    This job runs daily to manage trial expirations and send notifications.
    """
    print("Running Daily Subscription Management Job...")
    today = getdate(nowdate())
    notification_date = add_days(today, 7)

    trialing_subscriptions = frappe.get_all("Company Subscription",
        filters={"status": "Trialing"},
        fields=["name", "customer", "trial_ends_on"]
    )

    for sub in trialing_subscriptions:
        if not sub.trial_ends_on:
            continue

        trial_end_date = getdate(sub.trial_ends_on)

        if trial_end_date < today:
            _downgrade_subscription(sub)
        elif trial_end_date == notification_date:
            _send_trial_ending_notification(sub)

    print("Daily Subscription Management Job Complete.")


def _downgrade_subscription(subscription_info):
    """Downgrades a single subscription to the default free plan."""
    try:
        settings = frappe.get_doc("Subscription Settings")
        free_plan = settings.default_free_plan
        if not free_plan:
            frappe.log_error("No default free plan set in Subscription Settings.", "Subscription Downgrade Failed")
            return

        sub_doc = frappe.get_doc("Company Subscription", subscription_info.name)
        sub_doc.plan = free_plan
        sub_doc.status = "Downgraded"
        sub_doc.trial_ends_on = None
        sub_doc.next_billing_date = None
        sub_doc.save(ignore_permissions=True)

        frappe.db.commit()
        print(f"Subscription {subscription_info.name} has been downgraded.")
    except Exception:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), f"Subscription Downgrade Failed for {subscription_info.name}")


def _send_trial_ending_notification(subscription_info):
    """Sends a trial ending notification email to the company admin."""
    try:
        customer = frappe.get_doc("Customer", subscription_info.customer)
        if not customer.email:
            frappe.log_error(f"Customer {customer.name} for subscription {subscription_info.name} has no email address.", "Trial Notification Failed")
            return

        email_context = {
            "company_name": customer.customer_name,
            "admin_name": customer.customer_name
        }

        frappe.sendmail(
            recipients=[customer.email],
            template="Trial Ending Soon",
            args=email_context,
            now=True
        )
        print(f"Sent trial ending notification for subscription {subscription_info.name}")
    except Exception:
        frappe.log_error(frappe.get_traceback(), f"Trial Notification Email Failed for {subscription_info.name}")


def cleanup_failed_provisions():
    """
    Finds and deletes tenant sites that are stuck in a failed provisioning state.
    """
    print("Running Daily Failed Provision Cleanup Job...")

    # Calculate the cutoff date (24 hours ago)
    cutoff_date = now_datetime() - timedelta(days=1)

    # Find subscriptions that are older than the cutoff and still in a failed state
    failed_subscriptions = frappe.get_all("Company Subscription",
        filters={
            "creation": ["<", cutoff_date],
            "status": ["in", ["Provisioning", "Setup Failed"]]
        },
        fields=["name", "site_name", "customer"]
    )

    if not failed_subscriptions:
        print("No failed provisions to clean up.")
        return

    print(f"Found {len(failed_subscriptions)} failed provisions to clean up...")
    bench_path = frappe.conf.get("bench_path")

    for sub in failed_subscriptions:
        site_name = sub.get("site_name")
        print(f"  - Processing subscription {sub.name} for site {site_name}...")

        if not bench_path:
            frappe.log_error("`bench_path` not set in site_config.json. Cannot drop site.", "Tenant Cleanup Failed")
            continue

        try:
            # Check if the site exists before trying to drop it
            site_path = os.path.join(bench_path, "sites", site_name)
            if os.path.exists(site_path):
                # Drop the site and its database
                drop_command = ["bench", "drop-site", site_name, "--drop-db", "--force"]
                subprocess.run(drop_command, cwd=bench_path, check=True, capture_output=True, text=True)
                print(f"    - Successfully dropped site {site_name}.")

            # Delete the related documents on the control panel
            frappe.delete_doc("Company Subscription", sub.name, ignore_permissions=True, force=True)
            frappe.delete_doc("Customer", sub.customer, ignore_permissions=True, force=True)
            print(f"    - Successfully deleted subscription and customer records.")

            frappe.db.commit()

        except subprocess.CalledProcessError as e:
            frappe.db.rollback()
            error_message = f"STDOUT: {e.stdout}\nSTDERR: {e.stderr}"
            frappe.log_error(error_message, f"Tenant Cleanup: Bench Command Failed for {site_name}")
        except Exception as e:
            frappe.db.rollback()
            frappe.log_error(frappe.get_traceback(), f"Tenant Cleanup: Failed to process {sub.name}")

    print("Failed Provision Cleanup Job Complete.")


# ------------------------------------------------------------------------------
# Weekly Job
# ------------------------------------------------------------------------------

def run_weekly_maintenance():
    """
    This job runs weekly to perform automated maintenance tasks.
    """
    print("Running Weekly Maintenance Job...")
    print("Weekly Maintenance Job Complete.")


# ------------------------------------------------------------------------------
# Monthly Job
# ------------------------------------------------------------------------------

def generate_subscription_invoices():
    """
    This job runs monthly to generate sales invoices for active subscriptions.
    """
    print("Running Monthly Subscription Billing Job...")
    provider_company = frappe.db.get_default("company")
    if not provider_company:
        print("Default company not set in System Settings. Cannot generate invoices.")
        frappe.log_error("Default company not set.", "Subscription Billing Failed")
        return

    settings = frappe.get_doc("Subscription Settings")
    payment_gateway = settings.default_payment_gateway
    if not payment_gateway:
        print("Default payment gateway not set in Subscription Settings.")
        frappe.log_error("Default payment gateway not set.", "Subscription Billing Warning")


    today = getdate(nowdate())
    due_subscriptions = frappe.get_all("Company Subscription",
        filters={
            "status": "Active",
            "next_billing_date": ["<=", today]
        },
        fields=["name", "customer", "plan"]
    )

    for sub in due_subscriptions:
        try:
            plan = frappe.get_doc("Subscription Plan", sub.plan)

            if not plan.item or not plan.rate:
                frappe.log_error(f"Subscription Plan {plan.name} is missing Billing Item or Rate.", f"Billing Failed for {sub.name}")
                continue

            customer = frappe.get_doc("Customer", sub.customer)

            invoice = frappe.get_doc({
                "doctype": "Sales Invoice",
                "company": provider_company,
                "customer": customer.name,
                "due_date": add_days(today, 15),
                "items": [{
                    "item_code": plan.item,
                    "rate": plan.rate,
                    "qty": 1
                }]
            })
            invoice.insert(ignore_permissions=True)
            invoice.submit()
            print(f"Created Sales Invoice {invoice.name} for subscription {sub.name}")

            # Attempt to automatically pay the invoice
            _charge_invoice(invoice, customer, settings)

            # Update next billing date
            sub_doc = frappe.get_doc("Company Subscription", sub.name)
            if plan.billing_cycle == 'Monthly':
                sub_doc.next_billing_date = add_months(sub_doc.next_billing_date, 1)
            elif plan.billing_cycle == 'Yearly':
                sub_doc.next_billing_date = add_years(sub_doc.next_billing_date, 1)
            sub_doc.save(ignore_permissions=True)

            frappe.db.commit()

        except Exception:
            frappe.db.rollback()
            frappe.log_error(frappe.get_traceback(), f"Failed to generate invoice for subscription {sub.name}")

    print("Monthly Subscription Billing Job Complete.")


def _charge_invoice(invoice, customer, settings):
    """
    Charges a sales invoice using the customer's default payment method on Stripe.
    """
    if not customer.stripe_customer_id:
        print(f"Customer {customer.name} does not have a saved payment method. Skipping auto-charge.")
        return

    try:
        stripe.api_key = settings.get_password("stripe_secret_key")
        if not stripe.api_key:
            frappe.log_error("Stripe is not configured.", "Auto-charge Failed")
            return

        # Create a PaymentIntent to charge the customer
        payment_intent = stripe.PaymentIntent.create(
            amount=int(invoice.grand_total * 100),  # Amount in cents
            currency=invoice.currency.lower(),
            customer=customer.stripe_customer_id,
            payment_method=stripe.Customer.retrieve(customer.stripe_customer_id).invoice_settings.default_payment_method,
            off_session=True, # This allows charging the customer without them being present
            confirm=True, # This confirms the payment immediately
            description=f"Payment for invoice {invoice.name}"
        )

        if payment_intent.status == 'succeeded':
            print(f"Successfully charged customer {customer.name} for invoice {invoice.name}")

            # Create a Payment Entry in Frappe to record the payment
            pe = frappe.get_doc({
                "doctype": "Payment Entry",
                "payment_type": "Receive",
                "mode_of_payment": settings.default_payment_gateway,
                "party_type": "Customer",
                "party": customer.name,
                "paid_amount": invoice.grand_total,
                "received_amount": invoice.grand_total,
                "references": [{
                    "reference_doctype": "Sales Invoice",
                    "reference_name": invoice.name,
                    "allocated_amount": invoice.grand_total
                }]
            })
            pe.insert(ignore_permissions=True)
            pe.submit()
            print(f"Created Payment Entry {pe.name} for invoice {invoice.name}")

        else:
            # Payment failed
            frappe.log_error(f"Stripe charge failed for invoice {invoice.name}. Status: {payment_intent.status}", "Auto-charge Failed")

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), f"Auto-charge failed for invoice {invoice.name}")

