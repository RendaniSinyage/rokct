# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
# This file will contain APIs related to tenant provisioning.
import frappe
from frappe.utils import validate_email_address

def _validate_provisioning_input(plan, email, password, first_name, last_name, company_name, currency, country, industry):
    """Helper function to validate inputs for the provisioning API."""
    # Check for required fields
    if not all([plan, email, password, company_name, currency, country]):
        frappe.throw("Required fields are missing. Please provide plan, email, password, company name, currency, and country.", title="Missing Information")

    # Validate password length
    if len(password) < 8:
        frappe.throw("Password must be at least 8 characters long.", title="Weak Password")

    # Validate email format
    try:
        validate_email_address(email, throw=True)
    except frappe.exceptions.ValidationError:
        frappe.throw("You must provide a valid email address.", title="Invalid Email")

    # Check if a user with this email already exists on the control panel
    if frappe.db.exists("User", {"email": email}):
        frappe.throw("A user with this email address already exists.", title="Email Already Registered")

    # Check if a customer with this email already exists
    if frappe.db.exists("Customer", {"customer_primary_email": email}):
        frappe.throw("A customer account with this email address already exists.", title="Email Already Registered")

    # Check if the subscription plan exists
    if not frappe.db.exists("Subscription Plan", plan):
        frappe.throw(f"Subscription Plan '{plan}' not found.", title="Invalid Plan")

    # Check if the currency exists
    if not frappe.db.exists("Currency", {"name": currency, "enabled": 1}):
        frappe.throw(f"Currency '{currency}' is not enabled or does not exist.", title="Invalid Currency")

    # Check for non-empty strings for other fields
    if not all(isinstance(s, str) and s.strip() for s in [first_name, last_name, company_name, country, industry]):
        frappe.throw("First name, last name, company name, country, and industry must be non-empty strings.", title="Invalid Input")


@frappe.whitelist()
def provision_new_tenant(plan, email, password, first_name, last_name, company_name, currency, country, industry):
    """
    Starts the process for provisioning a new tenant site.
    This is called from the main frontend after a successful signup.
    It creates the necessary records and enqueues a background job to do the heavy lifting.
    """
    # This API should only ever run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")

    # 1. Validate all inputs
    _validate_provisioning_input(plan, email, password, first_name, last_name, company_name, currency, country, industry)

    # 2. Prevent trial abuse and check for existing subscriptions
    customer_id = frappe.db.get_value("Customer", {"customer_name": company_name})
    if customer_id:
        # Check if the new plan is a trial plan
        new_plan = frappe.get_doc("Subscription Plan", plan)
        new_plan.reload() # Ensure custom fields are loaded
        if new_plan.trial_period_days > 0:
            # Check if this customer has had a trial before using a direct SQL query for efficiency
            had_previous_trial = frappe.db.sql("""
                SELECT cs.name
                FROM `tabCompany Subscription` cs
                JOIN `tabSubscription Plan` sp ON cs.plan = sp.name
                WHERE cs.customer = %(customer_id)s AND sp.trial_period_days > 0
                LIMIT 1
            """, {"customer_id": customer_id})

            if had_previous_trial:
                return {
                    "status": "failed",
                    "alert": {
                        "title": "Not Eligible for Trial",
                        "message": "This account has already had a trial period and is not eligible for another. Please choose a paid plan."
                    }
                }

        # Then, check for any existing, non-dropped subscription
        if frappe.db.exists("Company Subscription", {"customer": customer_id, "status": ["!=", "Dropped"]}):
            return {
                "status": "failed",
                "alert": {
                    "title": "Existing Subscription Found",
                    "message": f"A subscription for '{company_name}' already exists. If you need assistance, please contact support."
                }
            }

    # 3. Determine site name and check for conflicts
    tenant_domain = frappe.conf.get("tenant_domain")
    if not tenant_domain:
        frappe.throw("`tenant_domain` not set in control plane site_config.json")

    # Generate site name based on company name
    words = company_name.strip().split()
    if len(words) > 1:
        # Multi-word name: create an acronym
        site_prefix = "".join(word[0] for word in words).lower()
    else:
        # Single-word name: use the sanitized word
        site_prefix = words[0].strip().lower().replace('.', '').replace('_', '-').replace(' ', '-')

    site_name = f"{site_prefix}.{tenant_domain}"

    existing_subscription = frappe.db.get_value("Company Subscription", {"site_name": site_name}, ["customer"], as_dict=True)
    if existing_subscription:
        customer_name = existing_subscription.customer
        # This is not an error, but an alert to the frontend that this company is already a customer.
        # We halt the process and return a specific JSON structure.
        return {
            "status": "failed",
            "alert": {
                "title": "Site Name Conflict",
                "message": f"The generated site name '{site_name}' is already in use by '{customer_name}'. Please choose a different company name to resolve the conflict."
            }
        }

    # 4. Create the subscription record in the control plane
    try:
        subscription = create_subscription_record(plan, email, company_name, industry, site_name, currency)
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Tenant Provisioning: Subscription Record Failed")
        frappe.throw(f"Failed to create subscription record: {e}")

    # 5. Enqueue a background job to create the site
    verification_token = frappe.generate_hash(length=48)

    frappe.enqueue(
        "rokct.rokct.control_panel.tasks.create_tenant_site_job",
        queue="long",
        timeout=1500, # 25 minutes, to be safe
        job_name=f"provision-site-{site_name}",
        subscription_id=subscription.name,
        site_name=site_name,
        user_details={
            "email": email,
            "password": password,
            "first_name": first_name,
            "last_name": last_name,
            "company_name": company_name,
            "currency": currency,
            "country": country,
            "verification_token": verification_token
        }
    )

    return {
        "status": "success",
        "message": f"Site {site_name} is being set up. You will receive an email shortly.",
        "site_name": site_name
    }


def create_subscription_record(plan, email, company_name, industry, site_name, currency):
    """
    Creates the Customer and Company Subscription records.
    """
    from frappe.utils import nowdate, add_days, add_months, add_years

    # 1. Ensure the Industry Type exists before creating the customer
    if not frappe.db.exists("Industry Type", industry):
        frappe.get_doc({
            "doctype": "Industry Type",
            "name": industry
        }).insert(ignore_permissions=True)
        print(f"Created missing Industry Type: {industry}")

    # 2. Find or create a Customer record for the new tenant
    existing_customer = frappe.db.get_value("Customer", {"customer_name": company_name}, "name")
    if existing_customer:
        customer = frappe.get_doc("Customer", existing_customer)
    else:
        customer_group = frappe.db.get_default("customer_group")
        customer = frappe.get_doc({
            "doctype": "Customer",
            "customer_name": company_name,
            "customer_group": customer_group,
            "industry": industry,
            "default_currency": currency,
            "customer_primary_email": email,
        }).insert(ignore_permissions=True)

    # 2. Create the subscription record
    subscription_plan = frappe.get_doc("Subscription Plan", plan)
    subscription_plan.reload() # Ensure custom fields are loaded

    # Determine initial status and dates
    status = "Active"
    trial_ends_on = None
    next_billing_date = None

    if subscription_plan.cost == 0:
        status = "Free"
    elif subscription_plan.trial_period_days > 0:
        status = "Trialing"
        trial_ends_on = add_days(nowdate(), subscription_plan.trial_period_days)
        # Billing starts after the trial
        if subscription_plan.billing_cycle == 'Monthly':
            next_billing_date = add_months(trial_ends_on, 1)
        elif subscription_plan.billing_cycle == 'Yearly':
            next_billing_date = add_years(trial_ends_on, 1)
    else: # Paid plan with no trial
        if subscription_plan.billing_cycle == 'Monthly':
            next_billing_date = add_months(nowdate(), 1)
        elif subscription_plan.billing_cycle == 'Yearly':
            next_billing_date = add_years(nowdate(), 1)

    subscription = frappe.get_doc({
        "doctype": "Company Subscription",
        "customer": customer.name,
        "site_name": site_name,
        "plan": plan,
        "status": status,
        "trial_ends_on": trial_ends_on,
        "subscription_start_date": nowdate(),
        "next_billing_date": next_billing_date,
    })

    # Set the password on the doc object before insert, which is the most reliable way.
    subscription.set("api_secret", frappe.generate_hash(length=48))
    subscription.insert(ignore_permissions=True)

    frappe.db.commit()
    return subscription