import frappe

app_name = "rokct"
app_title = "ROKCT"
app_publisher = "ROKCT Holdings"
app_description = "All custom work lives here"
app_logo_url = "/assets/rokct/images/logo_dark.svg"
app_email = "admin@rokct.ai"
app_license = "mit"

# Apps
# ------------------

# required_apps = []

# Each item in the list will be shown as an app in the apps page
# add_to_apps_screen = [
#       {
#               "name": "rokct",
#               "logo": "/assets/rokct/logo.png",
#               "title": "ROKCT CUSTOMIZATIONS",
#               "route": "/rokct",
#               "has_permission": "rokct.api.permission.has_app_permission"
#       }
# ]

# Includes in <head>
# ------------------

# include js, css files in header of desk.html
# app_include_css = "/assets/rokct/css/rokct.css"
# app_include_js = "/assets/rokct/js/rokct.js"

# include js, css files in header of web template
# web_include_css = "/assets/rokct/css/rokct.css"
# web_include_js = "/assets/rokct/js/rokct.js"

# include custom scss in every website theme (without file extension ".scss")
# website_theme_scss = "rokct/public/scss/website"

# include js in page
# page_js = {"page" : "public/js/file.js"}

# include js in doctype views
# doctype_js = {"doctype" : "public/js/doctype.js"}
doctype_list_js = {
    "Company Subscription": "public/js/company_subscription_list.js"
}
# doctype_tree_js = {"doctype" : "public/js/doctype_tree.js"}
# doctype_calendar_js = {"doctype" : "public/js/doctype_calendar.js"}

# Svg Icons
# ------------------
# include app icons in desk
# app_include_icons = "rokct/public/icons.svg"

# Home Pages
# ----------

# application home page (will override Website Settings)
# home_page = "swagger"

# website user home page (by Role)
# role_home_page = {
#       "Role": "home_page"
# }

# Generators
# ----------

# automatically create page for each record of this doctype
# website_generators = ["Web Page"]

# Jinja
# ----------

# add methods and filters to jinja environment
# jinja = {
#       "methods": "rokct.utils.jinja_methods",
#       "filters": "rokct.utils.jinja_filters"
# }

# Installation
# ------------

before_install = "rokct.install.before_install"
after_install = "rokct.install.after_install"

# Uninstallation
# ------------

before_uninstall = "rokct.rokct.flutter_builder.utils.prevent_uninstall_if_build_active"
# after_uninstall = "rokct.uninstall.after_uninstall"

# Integration Setup
# ------------------
# To set up dependencies/integrations with other apps
# Name of the app being installed is passed as an argument

# before_app_install = "rokct.utils.before_app_install"
# after_app_install = "rokct.rokct.utils.update_site_apps_txt"

# Integration Cleanup
# -------------------
# To clean up dependencies/integrations with other apps
# Name of the app being uninstalled is passed as an argument

# before_app_uninstall = "rokct.utils.before_app_uninstall"
after_app_uninstall = "rokct.rokct.utils.update_site_apps_txt"

# Desk Notifications
# ------------------
# See frappe.core.notifications.get_notification_config

# notification_config = "rokct.notifications.get_notification_config"

# Permissions
# -----------
# Permissions evaluated in scripted ways

# has_permission = {
#       "Event": "frappe.desk.doctype.event.event.has_permission",
# }

# DocType Class
# ---------------
# Override standard doctype classes

override_doctype_class = {
      "File": "rokct.rokct.overrides.CustomFile"
}

# Document Events
# ---------------
# Hook on document methods and events

doc_events = {
    "Customer": {
        "on_trash": "rokct.rokct.utils.customer.on_trash_customer"
    },
    "Company Subscription": {
        "on_update": "rokct.rokct.utils.company_subscription.on_update_company_subscription"
    }
}

# Scheduled Tasks
# ---------------

def get_safe_scheduler_events():
	"""
	Safely get scheduler events by checking if frappe.conf exists.
	This prevents crashes during installation where frappe.conf is not yet available.
	"""
	# This function is called at import time, so we must be defensive.
	if not hasattr(frappe, "conf") or not frappe.conf:
		return {}

	app_role = frappe.conf.get("app_role", "tenant")
	events = {}
	if app_role == "control_panel":
		events["daily"] = [
			"rokct.rokct.control_panel.tasks.manage_daily_subscriptions",
			"rokct.rokct.control_panel.tasks.cleanup_unverified_tenants",
			"rokct.rokct.tasks.manage_daily_tenders",
			"rokct.rokct.control_panel.tasks.cleanup_failed_provisions",
		]
		events["weekly"] = ["rokct.rokct.control_panel.tasks.run_weekly_maintenance"]
		events["monthly"] = ["rokct.rokct.control_panel.tasks.generate_subscription_invoices"]
	else:  # tenant
		events["daily"] = [
			"rokct.rokct.tasks.manage_daily_tenders",
			"rokct.rokct.tenant.tasks.disable_expired_support_users",
			"rokct.rokct.tenant.tasks.report_active_user_count",
			"rokct.paas.tasks.remove_expired_stories"
		]
	return events

scheduler_events = get_safe_scheduler_events()


# Testing
# -------

# before_tests = "rokct.install.before_tests"

# Overriding Methods
# ------------------------------
#
override_whitelisted_methods = {
    "rokct.rokct.tenant.api.get_subscription_details": "rokct.rokct.tenant.api.get_subscription_details",
    "rokct.rokct.scripts.debug_provisioning.trigger_provisioning_for_debug": "rokct.rokct.scripts.debug_provisioning.trigger_provisioning_for_debug"
}

whitelisted_methods = {
    # Control Panel APIs
    "rokct.rokct.control_panel.api.get_subscription_status": "rokct.rokct.control_panel.api.get_subscription_status",
    "rokct.rokct.control_panel.api.update_user_count": "rokct.rokct.control_panel.api.update_user_count",
    "rokct.rokct.control_panel.provisioning.provision_new_tenant": "rokct.rokct.control_panel.provisioning.provision_new_tenant",
    "rokct.rokct.control_panel.billing.save_payment_method": "rokct.rokct.control_panel.billing.save_payment_method",
    "rokct.rokct.control_panel.billing.reinstate_subscription": "rokct.rokct.control_panel.billing.reinstate_subscription",
    "rokct.rokct.control_panel.support.grant_support_access": "rokct.rokct.control_panel.support.grant_support_access",
    "rokct.rokct.control_panel.support.revoke_support_access": "rokct.rokct.control_panel.support.revoke_support_access",

    # Tenant APIs
    "rokct.rokct.tenant.api.initial_setup": "rokct.rokct.tenant.api.initial_setup",
    "rokct.rokct.tenant.api.create_temporary_support_user": "rokct.rokct.tenant.api.create_temporary_support_user",
    "rokct.rokct.tenant.api.disable_temporary_support_user": "rokct.rokct.tenant.api.disable_temporary_support_user",
    "rokct.rokct.tenant.api.create_sales_invoice": "rokct.rokct.tenant.api.create_sales_invoice",
    "rokct.rokct.tenant.api.log_frontend_error": "rokct.rokct.tenant.api.log_frontend_error",
    "rokct.rokct.tenant.api.get_subscription_details": "rokct.rokct.tenant.api.get_subscription_details",
    "rokct.rokct.scripts.setup_control_panel.configure_control_panel": "rokct.rokct.scripts.setup_control_panel.configure_control_panel"
}
#
# each overriding function accepts a `data` argument;
# generated from the base implementation of the doctype dashboard,
# along with any modifications made in other Frappe apps
override_doctype_dashboards = {
      "Competitor": "rokct.rokct.doctype.competitor.competitor.get_dashboard_data"
}

fixtures = [
    "Property Setter",
    "Role",
    "Role Permission",
    "Custom Field",
    "Workspace",
    "DocType Card",
    "Dashboard Chart",
    "Dashboard Chart Source",
    "Shortcut",
    "Tender Category",
    "Province",
    "Organ of State",
    "Tender Type",
    "Email Template"
]

# exempt linked doctypes from being automatically cancelled
#
# auto_cancel_exempted_doctypes = ["Auto Repeat"]

# Ignore links to specified DocTypes when deleting documents
# -----------------------------------------------------------

ignore_links_on_delete = ["Company Subscription"]

# Request Events
# ----------------
# before_request = ["rokct.rokct.utils.handle_login_redirect"]
# after_request = ["rokct.utils.after_request"]

# Job Events
# ----------
# before_job = ["rokct.utils.before_job"]
# after_job = ["rokct.utils.after_job"]

# User Data Protection
# --------------------

# user_data_fields = [
#       {
#               "doctype": "{doctype_1}",
#               "filter_by": "{filter_by}",
#               "redact_fields": ["{field_1}", "{field_2}"],
#               "partial": 1,
#       },
#       {
#               "doctype": "{doctype_2}",
#               "filter_by": "{filter_by}",
#               "partial": 1,
#       },
#       {
#               "doctype": "{doctype_3}",
#               "strict": False,
#       },
#       {
#               "doctype": "{doctype_4}"
#       }
# ]

# Authentication and authorization
# --------------------------------

on_login = "rokct.rokct.permissions.sync_user_roles_on_login"

# auth_hooks = [
#       "rokct.auth.validate"
# ]

# Automatically update python controller files with type annotations for this app.
# export_python_type_annotations = True

# default_log_clearing_doctypes = {
#       "Logging DocType Name": 30  # days to retain logs
# }

# Add API v1 routes for DocType resources
website_route_rules = [
    {"from_route": "/api/v1/resource/<doctype>", "to_route": "frappe.api.handle_api_request"},
    {"from_route": "/api/v1/resource/<doctype>/<name>", "to_route": "frappe.api.handle_api_request"},
]