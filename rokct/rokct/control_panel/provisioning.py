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

    # 2. Determine site name and check for conflicts
    tenant_domain = frappe.conf.get("tenant_domain")
    if not tenant_domain:
        frappe.throw("`tenant_domain` not set in control plane site_config.json")

    # Sanitize company name for use in URL
    sanitized_company_name = company_name.strip().lower().replace(' ', '-').replace('_', '-').replace('.', '')
    site_name = f"{sanitized_company_name}.{tenant_domain}"

    if frappe.db.exists("Company Subscription", {"site_name": site_name}):
        frappe.throw(f"A site with the name {site_name} already exists. Please choose a different company name.", title="Site Already Exists")

    # 3. Create the subscription record in the control plane
    try:
        subscription = create_subscription_record(plan, company_name, industry, site_name, currency)
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Tenant Provisioning: Subscription Record Failed")
        frappe.throw(f"Failed to create subscription record: {e}")

    # 4. Enqueue a background job to create the site
    verification_token = frappe.generate_hash(length=48)

    frappe.enqueue(
        "rokct.control_panel.tasks.create_tenant_site_job",
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


def create_subscription_record(plan, company_name, industry, site_name, currency):
    """
    Creates the Customer and Company Subscription records.
    """
    from frappe.utils import nowdate, add_days, add_months, add_years

    # 1. Create a Customer record for the new tenant
    customer_group = frappe.db.get_default("customer_group")
    customer = frappe.get_doc({
        "doctype": "Customer",
        "customer_name": company_name,
        "customer_group": customer_group,
        "industry": industry,
        "default_currency": currency # Set the customer's default currency
    }).insert(ignore_permissions=True)

    # 2. Create the subscription record
    subscription_plan = frappe.get_doc("Subscription Plan", plan)

    trial_ends_on = None
    if not subscription_plan.is_free_plan and subscription_plan.trial_period_days:
        trial_ends_on = add_days(nowdate(), subscription_plan.trial_period_days)

    next_billing_date = None
    if not subscription_plan.is_free_plan:
        if subscription_plan.billing_cycle == 'Monthly':
            next_billing_date = add_months(nowdate(), 1)
        elif subscription_plan.billing_cycle == 'Yearly':
            next_billing_date = add_years(nowdate(), 1)

    api_secret = frappe.generate_hash(length=48)

    subscription = frappe.get_doc({
        "doctype": "Company Subscription",
        "customer": customer.name,
        "site_name": site_name,
        "plan": plan,
        "status": "Pending", # Status is now 'Pending' until the background job starts
        "trial_ends_on": trial_ends_on,
        "subscription_start_date": nowdate(),
        "next_billing_date": next_billing_date,
    }).insert(ignore_permissions=True)

    # Store the API secret separately as it's a password field
    subscription.api_secret = api_secret
    subscription.save(ignore_permissions=True)

    frappe.db.commit()
    return subscription

