import frappe

@frappe.whitelist()
def get_weather(location: str):
    """
    Proxy endpoint to get weather data from the control site, with tenant-side caching.
    This follows the same authentication pattern as other tenant-to-control-panel APIs.
    """
    if not location:
        frappe.throw("Location is a required parameter.")

    # Use a different cache key for the proxy to avoid conflicts
    cache_key = f"weather_proxy_{location.lower().replace(' ', '_')}"
    cached_data = frappe.cache().get_value(cache_key)

    if cached_data:
        return cached_data

    # Get connection details from site config (set during tenant provisioning)
    control_plane_url = frappe.conf.get("control_plane_url")
    api_secret = frappe.conf.get("api_secret")

    if not control_plane_url or not api_secret:
        frappe.log_error("Tenant site is not configured to communicate with the control panel.", "Weather Proxy Error")
        frappe.throw("Platform communication is not configured.", title="Configuration Error")

    # Construct the secure API call
    scheme = frappe.conf.get("control_plane_scheme", "https")
    api_url = f"{scheme}://{control_plane_url}/api/method/rokct.rokct.api.get_weather"
    headers = {
        "Authorization": f"Bearer {api_secret}",
        "Accept": "application/json"
    }

    try:
        # Use frappe.make_get_request which is a wrapper around requests
        # and handles logging and exceptions in a standard way.
        response = frappe.make_get_request(api_url, headers=headers, params={"location": location})

        # Cache the successful response for 10 minutes on the tenant site
        frappe.cache().set_value(cache_key, response, expires_in_sec=600)

        return response

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Weather Proxy API Error")
        frappe.throw(f"An error occurred while fetching weather data from the control plane: {e}")

@frappe.whitelist(allow_guest=True)
def api_status():
    """
    Returns a simple status of the API.
    """
    return {
        "status": "ok",
        "version": frappe.get_attr("frappe.__version__"),
        "user": frappe.session.user
    }


@frappe.whitelist(allow_guest=True)
def get_languages():
    """
    Returns a list of all enabled languages.
    """
    return frappe.get_all(
        "Language",
        filters={"enabled": 1},
        fields=["name", "language_name"]
    )


@frappe.whitelist(allow_guest=True)
def get_currencies():
    """
    Returns a list of all enabled currencies.
    """
    return frappe.get_all(
        "Currency",
        filters={"enabled": 1},
        fields=["name", "currency_name", "symbol"]
    )