import frappe

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