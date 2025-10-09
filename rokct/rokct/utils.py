# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe

def get_dynamic_logo_url():
	"""
	Returns the appropriate logo URL based on the user's desk theme.
	Defaults to the light logo if the theme is not 'Dark' or if an error occurs.
	"""
	try:
		# Avoid running during install/setup where user session may not be available
		if frappe.session.user and frappe.session.user != "Guest":
			user_theme = frappe.db.get_value("User", frappe.session.user, "desk_theme")
			if user_theme == "Dark":
				return "/assets/rokct/images/logo_dark.svg"
	except Exception:
		# Fallback in case of any error (e.g., during install or if user is not logged in)
		pass

	# Default to the light logo
	return "/assets/rokct/images/logo.svg"


def handle_login_redirect():
    """
    This function is called before each request.
    It checks if the request is for the /login page and if a custom redirect
    URL is set for the tenant. If so, it performs a 301 redirect.
    """
    # Only run this logic on tenant sites, not the control plane
    if frappe.conf.get("app_role") != "tenant":
        return

    # Check if the current request is for the login page
    if frappe.request and frappe.request.path == "/login":
        # Get the custom redirect URL from Website Settings, using a cached call for performance
        redirect_url = frappe.db.get_single_value("Website Settings", "custom_login_redirect_url")

        if redirect_url:
            # If a URL is set, immediately throw a redirect exception
            frappe.local.response["type"] = "redirect"
            frappe.local.response["location"] = redirect_url
            frappe.local.response["http_status_code"] = 301
            raise frappe.Redirect