import frappe
import os
import json
from frappe.utils import validate_email_address, get_url
from rokct.rokct.tenant.utils import send_tenant_email

def _notify_control_panel_of_verification():
    """Makes a secure backend call to the control panel to mark the subscription as verified."""
    try:
        control_plane_url = frappe.conf.get("control_plane_url")
        api_secret = frappe.conf.get("api_secret")

        if not control_plane_url or not api_secret:
            frappe.log_error("Tenant site is not configured to communicate with the control panel.", "Verification Notification Error")
            return

        scheme = frappe.conf.get("control_plane_scheme", "https")
        api_url = f"{scheme}://{control_plane_url}/api/method/rokct.control_panel.api.mark_subscription_as_verified"

        headers = {"Authorization": f"Bearer {api_secret}"}
        # The site name is implicitly sent via the request's Host header,
        # which the control panel will use to identify the subscription.
        response = frappe.make_post_request(api_url, headers=headers)

        if response.get("status") != "success":
            frappe.log_error(f"Failed to notify control panel of verification. Response: {response}", "Verification Notification Error")

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Verification Notification Failed")


@frappe.whitelist(allow_guest=True)
def initial_setup(email, password, first_name, last_name, company_name, api_secret, control_plane_url, currency, country, verification_token, login_redirect_url):
    """
    Sets up the first user and company.
    This is called by the control panel during provisioning.
    """
    # --- Validation ---
    params_to_check = {
        "email": email,
        "password": password,
        "first_name": first_name,
        "last_name": last_name,
        "company_name": company_name,
        "api_secret": api_secret,
        "control_plane_url": control_plane_url,
        "currency": currency,
        "country": country,
        "verification_token": verification_token,
    }

    for param_name, param_value in params_to_check.items():
        if not param_value:
            frappe.throw(f"Parameter '{param_name}' is missing or empty.", title="Missing Information")

    if login_redirect_url is None:
        frappe.throw("The 'login_redirect_url' parameter must be provided, even if it's an empty string.", title="Missing Information")

    try:
        validate_email_address(email, throw=True)
    except frappe.exceptions.ValidationError:
        frappe.throw("You must provide a valid email address.", title="Invalid Email")

    if len(password) < 8:
        frappe.throw("Password must be at least 8 characters long.", title="Weak Password")

    received_secret = frappe.local.request.headers.get("X-Rokct-Secret")
    if not received_secret:
        frappe.throw("Missing X-Rokct-Secret header.", frappe.AuthenticationError)

    if received_secret != api_secret:
        frappe.throw("Authentication failed. Secrets do not match.", frappe.AuthenticationError)

    if frappe.db.exists("User", {"email": email}):
        frappe.log_error(f"Initial setup called for existing user {email}", "Tenant Initial Setup Warning")
        return {"status": "warning", "message": f"User {email} already exists."}
    # --- End Validation ---

    try:
        # Store control panel details for future communication
        # Manually update site_config.json to bypass potential framework init issues.
        site_config_path = frappe.get_site_path("site_config.json")
        with open(site_config_path, "r") as f:
            site_config = json.load(f)

        site_config["api_secret"] = api_secret
        site_config["control_plane_url"] = control_plane_url

        with open(site_config_path, "w") as f:
            json.dump(site_config, f, indent=4)

        # Create the first user
        user = frappe.get_doc({
            "doctype": "User",
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "send_welcome_email": 0,
            "email_verification_token": verification_token # Use token from control panel
        })
        user.set("new_password", password)
        user.insert(ignore_permissions=True)
        user.add_roles("System Manager", "Company User")

        # Configure the default company
        default_company_name = frappe.get_all("Company")[0].name
        default_company = frappe.get_doc("Company", default_company_name)
        default_company.company_name = company_name
        default_company.country = country
        default_company.default_currency = currency
        default_company.save(ignore_permissions=True)

        # Link user to the company
        # We need to reload the user doc here to prevent a race condition-like error
        # where the user object is not fully initialized before we try to append to its child table.
        user = frappe.get_doc("User", email)
        user.append("user_companies", {"company": default_company.name, "is_default": 1})
        user.save(ignore_permissions=True)

        # Mark setup as complete to bypass the wizard for the new tenant
        system_settings = frappe.get_doc("System Settings")
        system_settings.setup_complete = 1
        system_settings.save(ignore_permissions=True)

        # Disable signup and redirect /login to the main marketing site
        website_settings = frappe.get_doc("Website Settings", "Website Settings")
        website_settings.allow_signup = 0
        website_settings.home_page = "welcome" # Set tenant-specific homepage
        website_settings.save(ignore_permissions=True)

        if not frappe.db.exists("Redirect", {"source": "/login"}):
            frappe.get_doc({
                "doctype": "Redirect",
                "source": "/login",
                "target": login_redirect_url,
                "http_status_code": "301"
            }).insert(ignore_permissions=True)

        frappe.db.commit()
        return {"status": "success", "message": "Initial user and company setup complete."}

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Tenant Initial Setup Failed")
        frappe.throw(f"An error occurred during initial setup: {e}")

@frappe.whitelist(allow_guest=True)
def verify_my_email(token):
    """
    Verify a user's email address using a token from their welcome email.
    """
    if not token:
        frappe.respond_as_web_page("Invalid Link", "The verification link is missing a token.", indicator_color='red')
        return

    user = frappe.db.get_value("User", {"email_verification_token": token}, ["name", "enabled"])
    if not user:
        frappe.respond_as_web_page("Invalid Link", "This verification link is invalid or has already been used.", indicator_color='red')
        return

    if not user.enabled:
        frappe.respond_as_web_page("Account Disabled", "Your account has been disabled. Please contact support.", indicator_color='red')
        return

    user_doc = frappe.get_doc("User", user.name)
    user_doc.email_verification_token = None  # Invalidate the token
    user_doc.email_verified_at = frappe.utils.now_datetime()  # Set verification timestamp
    user_doc.save(ignore_permissions=True)

    # This is a fire-and-forget call. We don't need to block the user's
    # experience waiting for the response. The control panel will handle it.
    frappe.enqueue(_notify_control_panel_of_verification, queue="short")

    frappe.db.commit()

    frappe.respond_as_web_page(
        "Email Verified!",
        "Thank you for verifying your email address. You can now log in to your account.",
        indicator_color='green'
    )


@frappe.whitelist()
def resend_verification_email(email: str):
    """
    Resends the verification email for a given user.
    Can be called by the user themselves or a System Manager.
    """
    # Security: Ensure the logged-in user is the one requesting the resend, or is an admin.
    if frappe.session.user != email and "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action for another user.", frappe.PermissionError)

    try:
        user = frappe.get_doc("User", email)
        if user.email_verified_at:
            return {"status": "success", "message": "Email is already verified."}

        # Generate and store a new verification token
        token = frappe.generate_hash(length=48)
        user.email_verification_token = token
        user.save(ignore_permissions=True)

        # Get company name for email context
        default_company_link = next((d for d in user.user_companies if d.is_default), None)
        company_name = default_company_link.company if default_company_link else "Your Company"

        # Prepare context and send the email
        verification_url = get_url(f"/api/method/rokct.tenant.api.verify_my_email?token={token}")
        email_context = {
            "first_name": user.first_name,
            "company_name": company_name,
            "verification_url": verification_url
        }
        send_tenant_email(
            recipients=[user.email],
            template="Resend Verification",
            args=email_context,
            now=True
        )
        frappe.db.commit()
        return {"status": "success", "message": "Verification email sent."}
    except frappe.DoesNotExistError:
        return {"status": "error", "message": "User not found."}
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Resend Verification Email Failed")
        frappe.throw(f"An error occurred while resending the verification email: {e}")

@frappe.whitelist()
def get_visions():
    return frappe.get_all("Vision", fields=["name", "title", "description"])

@frappe.whitelist()
def get_pillars():
    return frappe.get_all("Pillar", fields=["name", "title", "description", "vision"])

@frappe.whitelist()
def get_strategic_objectives():
    return frappe.get_all("Strategic Objective", fields=["name", "title", "description", "pillar"])

@frappe.whitelist()
def get_kpis():
    return frappe.get_all("KPI", fields=["name", "title", "description", "strategic_objective"])

@frappe.whitelist()
def get_plan_on_a_page():
    return frappe.get_doc("Plan On A Page")

@frappe.whitelist()
def get_personal_mastery_goals():
    return frappe.get_all("Personal Mastery Goal", fields=["name", "title", "description"])

@frappe.whitelist()
def create_temporary_support_user(agent_id: str, reason: str, support_email_domain: str):
    """
    Creates a temporary support user with a descriptive name and System Manager role.
    """
    if frappe.conf.get("app_role") != "tenant":
        frappe.throw("This action can only be performed on a tenant site.", title="Action Not Allowed")

    # --- Authentication/Authorization ---
    api_secret = frappe.conf.get("api_secret")
    auth_header = frappe.local.request.headers.get("Authorization")
    if not api_secret or not auth_header or not auth_header.startswith("Bearer "):
        frappe.throw("Authentication failed: Missing credentials.", frappe.AuthenticationError)
    if auth_header.split(" ")[1] != api_secret:
        frappe.throw("Authentication failed: Invalid credentials.", frappe.AuthenticationError)
    # --- End Authentication ---

    # --- Input Validation ---
    if not all([agent_id, reason, support_email_domain]):
        frappe.throw("Agent ID, Reason, and Support Email Domain are required.", title="Missing Information")
    # --- End Validation ---

    try:
        # Construct a descriptive email for better audit trails
        support_email = f"support-{agent_id}-{reason}@{support_email_domain}"
        temp_password = frappe.generate_hash(length=16)

        # Check if this exact user already exists (e.g., from a failed previous run)
        if frappe.db.exists("User", support_email):
            frappe.delete_doc("User", support_email, force=True, ignore_permissions=True)


        user = frappe.get_doc({
            "doctype": "User",
            "email": support_email,
            "first_name": "ROKCT Support",
            "last_name": f"({reason})",
            "send_welcome_email": 0,
            "temporary_user_expires_on": frappe.utils.add_to_date(frappe.utils.now_datetime(), hours=24)
        })
        user.set("new_password", temp_password)
        user.insert(ignore_permissions=True)
        user.add_roles("System Manager")

        frappe.db.commit()
        return {"status": "success", "message": {"email": support_email, "password": temp_password}}

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Temporary Support User Creation Failed")
        frappe.throw(f"An error occurred during temporary user creation: {e}")

@frappe.whitelist()
def disable_temporary_support_user(support_user_email):
    """
    Disables a temporary support user account.
    """
    if frappe.conf.get("app_role") != "tenant":
        frappe.throw("This action can only be performed on a tenant site.", title="Action Not Allowed")

    # --- Input Validation ---
    if not support_user_email:
        frappe.throw("Support User Email is required.", title="Missing Information")
    try:
        validate_email_address(support_user_email, throw=True)
    except frappe.exceptions.ValidationError:
        frappe.throw("You must provide a valid email address.", title="Invalid Email")
    # --- End Validation ---

    api_secret = frappe.conf.get("api_secret")
    auth_header = frappe.local.request.headers.get("Authorization")

    if not api_secret or not auth_header or not auth_header.startswith("Bearer "):
        frappe.throw("Authentication failed: Missing credentials.")

    if auth_header.split(" ")[1] != api_secret:
        frappe.throw("Authentication failed: Invalid credentials.")

    try:
        if not frappe.db.exists("User", support_user_email):
            return {"status": "success", "message": "User already does not exist."}

        user = frappe.get_doc("User", support_user_email)
        user.enabled = 0
        user.save(ignore_permissions=True)

        frappe.db.commit()
        return {"status": "success", "message": f"Support user {support_user_email} has been disabled."}

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), f"Failed to disable support user {support_user_email}")
        frappe.throw(f"An error occurred while disabling the support user: {e}")

@frappe.whitelist()
def create_sales_invoice(invoice_data, recurring=False, frequency=None, end_date=None):
    """
    Creates a new Sales Invoice and, optionally, sets up a recurring schedule for it.
    """
    if frappe.conf.get("app_role") != "tenant":
        frappe.throw("This action can only be performed on a tenant site.", title="Action Not Allowed")

    # --- Input Validation ---
    if not isinstance(invoice_data, dict) or not invoice_data.get("customer") or not invoice_data.get("items"):
        frappe.throw("`invoice_data` must be a dictionary containing at least 'customer' and 'items'.", title="Invalid Input")

    if recurring:
        if not frequency or not end_date:
            frappe.throw("`frequency` and `end_date` are required for recurring invoices.", title="Missing Information")
        allowed_frequencies = ["Daily", "Weekly", "Monthly", "Quarterly", "Half-yearly", "Yearly"]
        if frequency not in allowed_frequencies:
            frappe.throw(f"Invalid frequency. Must be one of {', '.join(allowed_frequencies)}.", title="Invalid Input")
    # --- End Validation ---

    try:
        invoice_doc = frappe.get_doc(invoice_data)
        invoice_doc.insert(ignore_permissions=False)
        invoice_doc.submit()

        response_data = {"invoice_name": invoice_doc.name}
        if recurring:
            auto_repeat = frappe.get_doc({
                "doctype": "Auto Repeat", "reference_doctype": "Sales Invoice", "reference_document": invoice_doc.name,
                "frequency": frequency, "end_date": end_date
            }).insert(ignore_permissions=False)
            auto_repeat.submit()
            response_data["auto_repeat_name"] = auto_repeat.name
            response_data["message"] = f"Sales Invoice {invoice_doc.name} created and scheduled for recurring generation."
        else:
            response_data["message"] = f"Sales Invoice {invoice_doc.name} created successfully."

        frappe.db.commit()
        return response_data

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Failed to create Sales Invoice")
        frappe.throw(f"An error occurred while creating the Sales Invoice: {e}")

@frappe.whitelist()
def log_frontend_error(error_message, context=None):
    """
    Logs an error from the frontend to the backend.
    """
    if frappe.conf.get("app_role") != "tenant":
        frappe.throw("This action can only be performed on a tenant site.", title="Action Not Allowed")

    if not error_message or not isinstance(error_message, str) or not error_message.strip():
        return {"status": "error", "message": "error_message must be a non-empty string."}

    try:
        frappe.get_doc({
            "doctype": "Frontend Error Log", "error_message": error_message, "context": context,
            "user": frappe.session.user, "timestamp": frappe.utils.now_datetime()
        }).insert(ignore_permissions=True)

        frappe.db.commit()
        return {"status": "success", "message": "Error logged successfully."}

    except Exception:
        frappe.log_error(frappe.get_traceback(), "Failed to log frontend error")
        return {"status": "error", "message": "Failed to log error to backend."}

@frappe.whitelist()
def get_subscription_details():
    """
    A secure proxy API for the frontend to get subscription details.
    """
    if frappe.conf.get("app_role") != "tenant":
        frappe.throw("This action can only be performed on a tenant site.", title="Action Not Allowed")

    try:
        control_plane_url = frappe.conf.get("control_plane_url")
        api_secret = frappe.conf.get("api_secret")

        if not control_plane_url or not api_secret:
            frappe.log_error("Tenant site is not configured to communicate with the control panel.", "Proxy API Error")
            frappe.throw("Platform communication is not configured.", title="Configuration Error")

        scheme = frappe.conf.get("control_plane_scheme", "https")
        api_url = f"{scheme}://{control_plane_url}/api/method/rokct.control_panel.api.get_subscription_status"

        headers = {"Authorization": f"Bearer {api_secret}"}
        response = frappe.make_post_request(api_url, headers=headers)

        return response.get("message")

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Subscription Details Proxy Failed")
        frappe.throw("An error occurred while fetching subscription details.")


@frappe.whitelist()
def save_email_settings(settings: dict):
    """
    Saves the tenant's custom email settings.
    """
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", frappe.PermissionError)

    if not isinstance(settings, dict):
        frappe.throw("Settings must be a dictionary.", frappe.ValidationError)

    try:
        doc = frappe.get_doc("Tenant Email Settings")
        doc.update(settings)
        doc.save(ignore_permissions=True)
        frappe.db.commit()
        return {"status": "success", "message": "Email settings saved successfully."}
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Failed to save email settings")
        frappe.throw(f"An error occurred while saving email settings: {e}")


@frappe.whitelist()
def get_welcome_email_details():
    """
    Returns the details needed to send a welcome email to the primary user.
    This is called by the control panel.
    """
    if frappe.conf.get("app_role") != "tenant":
        frappe.throw("This action can only be performed on a tenant site.", title="Action Not Allowed")

    # --- Authentication/Authorization ---
    api_secret = frappe.conf.get("api_secret")
    auth_header = frappe.local.request.headers.get("Authorization")
    if not api_secret or not auth_header or not auth_header.startswith("Bearer "):
        frappe.throw("Authentication failed: Missing credentials.", frappe.AuthenticationError)
    if auth_header.split(" ")[1] != api_secret:
        frappe.throw("Authentication failed: Invalid credentials.", frappe.AuthenticationError)
    # --- End Authentication ---

    try:
        # Find the first user who is a System Manager
        system_managers = frappe.get_all("User", filters={"role_profile_name": "System Manager", "enabled": 1}, fields=["name", "first_name", "email", "email_verification_token"], order_by="creation asc", limit=1)
        if not system_managers:
            frappe.throw("No primary user found to send welcome email to.", title="User Not Found")

        user = system_managers[0]

        return {
            "email": user.email,
            "first_name": user.first_name,
            "email_verification_token": user.email_verification_token
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Failed to get welcome email details")
        frappe.throw(f"An error occurred while getting welcome email details: {e}")

