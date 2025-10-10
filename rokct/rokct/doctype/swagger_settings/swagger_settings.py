# Copyright (c) 2024, ROKCT and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document
from rokct.swagger.swagger_generator import generate_swagger_json
import os
import json
import traceback

class SwaggerSettings(Document):
	pass

def run_swagger_generation_on_control_site():
	"""
	This function is called by hooks. It checks if the site is a control panel
	and then enqueues the swagger generation job.
	"""
	if frappe.get_conf().get("app_role") == "control_panel":
		frappe.enqueue(
			"rokct.swagger.swagger_generator.generate_swagger_json",
			queue="long",
			job_name="swagger_generation"
		)
		frappe.log_info("Swagger Generation Enqueued", "Swagger generation was enqueued by a hook on the control site.")

@frappe.whitelist()
def enqueue_swagger_generation():
	"""
	Enqueues the swagger generation job. This is called by the button in the UI.
	"""
	# Check for control panel role again as a security measure
	if frappe.get_conf().get("app_role") != "control_panel":
		frappe.throw(frappe._("Swagger generation can only be triggered from the control site."), title="Not Permitted")

	frappe.enqueue(
		"rokct.swagger.swagger_generator.generate_swagger_json",
		queue="long",
		job_name="swagger_generation"
	)
	return frappe._("Swagger generation has been successfully enqueued. It will be processed in the background.")


@frappe.whitelist()
def get_app_role():
	"""
	Returns the app_role from the site config to the client-side script.
	"""
	return frappe.get_conf().get("app_role")

@frappe.whitelist()
def get_installed_apps_list():
	"""
	Returns the cached list of installed apps from the database.
	The cache is populated by the 'cache_installed_apps' function.
	"""
	try:
		cached_apps = frappe.db.get_single_value("Swagger Settings", "installed_apps_cache")
		if cached_apps:
			return json.loads(cached_apps)
		else:
			# If cache is empty or not set, return an empty list.
			# The frontend should handle this gracefully.
			return []
	except Exception:
		frappe.log_error(f"Could not read or parse cached app list. Error: {traceback.format_exc()}")
		return [] # Return empty list on error to prevent frontend breakage.

def run_swagger_related_hooks():
	"""
	A single wrapper function to be called by system hooks.
	It handles caching the app list and then enqueues the swagger generation.
	"""
	cache_installed_apps()
	run_swagger_generation_on_control_site()

@frappe.whitelist()
def cache_installed_apps():
	"""
	Caches the list of installed apps in the Swagger Settings DocType
	using the reliable frappe.get_installed_apps() method.
	"""
	try:
		apps = frappe.get_installed_apps()

		# We will cache the list, even if it's empty, to reflect the current state.
		# The frontend is responsible for handling an empty list.
		frappe.db.set_value(
			"Swagger Settings",
			"Swagger Settings",
			"installed_apps_cache",
			json.dumps(apps or []), # Ensure we cache an empty list, not null
			update_modified=False
		)
		frappe.db.commit()
		frappe.logger().info(f"Successfully cached {len(apps)} installed apps.")
		return apps
	except Exception:
		# Log the full traceback in case of an unexpected error
		frappe.log_error(f"Failed to cache installed apps list. Error: {traceback.format_exc()}")
		# Return an empty list to prevent frontend errors
		return []