import frappe
from frappe.utils import nowdate, add_days, add_months, add_years
from frappe.utils.change_log import get_versions as frappe_get_versions
from rokct import __version__ as rokct_version
from ..paas import __version__ as paas_version

# TODO: This method of overriding the 'get_versions' core function via hooks.py
# is fragile and may break in future Frappe updates. A more robust solution
# should be investigated, such as a custom API endpoint for versioning.
@frappe.whitelist(allow_guest=True)
def get_versions():
    versions = frappe_get_versions()
    if 'rokct' in versions:
        versions['rokct']['version'] = rokct_version

    versions['paas'] = {
        'title': 'PaaS',
        'version': paas_version
    }
    return versions

@frappe.whitelist()
def deprecated_signup_with_company(email, password, first_name, last_name, company_name, currency, country, industry, plan=None):
    """
    API endpoint to handle the signup of a new company and its first user.
    This endpoint is atomic: it creates a new company, a new user, and a new subscription.
    It will fail if the user or company already exists.

    :param email: User's email address (must be unique).
    :param password: User's password.
    :param first_name: User's first name.
    :param last_name: User's last name.
    :param company_name: Name of the new company (must be unique).
    :param currency: Default currency for the new company.
    :param country: Country for the new company.
    :param plan: (Optional) The subscription plan to sign up for. If not provided, the default trial plan is used.
    :return: A dictionary with the status of the operation and a message.
    """
    if frappe.db.exists("User", email):
        frappe.throw(f"User with email {email} already exists.")

    if frappe.db.exists("Company", company_name):
        frappe.throw(f"Company with name {company_name} already exists.")

    company = None
    user = None

    try:
        # 1. Create Company
        company = frappe.get_doc({
            "doctype": "Company",
            "company_name": company_name,
            "default_currency": currency,
            "country": country,
            "industry": industry
        }).insert(ignore_permissions=True)

        # 2. Create User
        user = frappe.get_doc({
            "doctype": "User",
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "send_welcome_email": 0,
        })
        user.set("new_password", password)
        user.insert(ignore_permissions=True)

        # 3. Add Roles and Link to Company
        # The "Company User" is an admin, "Company Employee" is the base role.
        user.add_roles("Company User", "Company Employee")

        # This is the correct way to link a user to a company in a multi-tenant setup.
        # The user_companies table stores the list of companies a user has access to.
        user.append("user_companies", {
            "company": company.name,
            "is_default": 1
        })
        user.save(ignore_permissions=True)

        # 4. Create Subscription
        subscription_settings = frappe.get_doc("Subscription Settings")
        if not plan:
            plan = subscription_settings.default_trial_plan

        subscription_plan = frappe.get_doc("Subscription Plan", plan)
        subscription_plan.reload() # Ensure custom fields are loaded

        trial_ends_on = None
        if not subscription_plan.is_free_plan and subscription_plan.trial_period_days:
            trial_ends_on = add_days(nowdate(), subscription_plan.trial_period_days)

        next_billing_date = None
        if not subscription_plan.is_free_plan:
            if subscription_plan.billing_cycle == 'Monthly':
                next_billing_date = add_months(nowdate(), 1)
            elif subscription_plan.billing_cycle == 'Yearly':
                next_billing_date = add_years(nowdate(), 1)

        frappe.get_doc({
            "doctype": "Company Subscription",
            "company": company.name,
            "plan": plan,
            "status": "Trialing" if trial_ends_on else "Active",
            "trial_ends_on": trial_ends_on,
            "subscription_start_date": nowdate(),
            "next_billing_date": next_billing_date
        }).insert(ignore_permissions=True)

        if not subscription_plan.is_free_plan:
            company.reload()
            company.has_used_trial = 1
            company.save(ignore_permissions=True)

        frappe.db.commit()
        return {"status": "success", "message": f"User {email} and company {company_name} created successfully."}

    except Exception as e:
        frappe.db.rollback()
        # Clean up created documents on failure
        if user and frappe.db.exists("User", user.name):
            frappe.delete_doc("User", user.name, ignore_permissions=True)
        if company and frappe.db.exists("Company", company.name):
            frappe.delete_doc("Company", company.name, ignore_permissions=True)

        frappe.log_error(frappe.get_traceback(), "Signup Error")
        frappe.throw(f"An error occurred during signup: {e}")


@frappe.whitelist()
def get_weather(location: str):
    """
    Get weather data for a given location, with caching.
    This endpoint is intended to be called by tenant sites.
    """
    if not location:
        frappe.throw("Location is a required parameter.")

    # Check for special cases to use default location, mimicking Laravel logic
    weather_settings = frappe.get_doc("Weather Settings")
    default_location = weather_settings.default_location or "messina,za"

    # Simple check for coordinates (e.g., "-25.2,31.4") or "messina" related strings
    if "," in location or "messina" in location.lower() or "nancefield" in location.lower():
        location = default_location

    cache_key = f"weather_{location.lower().replace(' ', '_')}"
    cached_data = frappe.cache().get_value(cache_key)

    if cached_data:
        return cached_data

    try:
        from .weather import get_weather_data
        weather_data = get_weather_data(location)
        frappe.cache().set_value(cache_key, weather_data, expires_in_sec=43200)  # Cache for 12 hours
        return weather_data
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Weather API Error")
        frappe.throw(f"An error occurred while fetching weather data: {e}")

