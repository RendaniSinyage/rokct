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
	Returns a list of all installed apps for the current site by reading
	the cached list from the database.
	"""
	try:
		cached_apps = frappe.db.get_single_value("Swagger Settings", "installed_apps_cache")
		if cached_apps:
			return json.loads(cached_apps)
	except Exception:
		frappe.log_error(f"Could not read or parse cached app list. Falling back. Error: {traceback.format_exc()}")

	# Fallback to the direct method if cache is empty or fails
	return frappe.get_installed_apps()

def run_swagger_related_hooks():
	"""
	A single wrapper function to be called by system hooks.
	It handles caching the app list and then enqueues the swagger generation.
	"""
	cache_installed_apps()
	run_swagger_generation_on_control_site()

def cache_installed_apps():
	"""
	Reads the site's apps.txt file and caches the list in the Swagger Settings DocType.
	This is called via hooks on `on_migrate` and `on_update`.
	"""
	try:
		bench_path = frappe.utils.get_bench_path()
		site_name = frappe.local.site
		apps_txt_path = os.path.join(bench_path, "sites", site_name, "apps.txt")

		apps = []
		if os.path.exists(apps_txt_path):
			with open(apps_txt_path, "r") as f:
				apps = [line.strip() for line in f if line.strip()]
		else:
			# Fallback if apps.txt is not found for any reason
			apps = frappe.get_installed_apps()

		if apps:
			swagger_settings = frappe.get_single("Swagger Settings")
			swagger_settings.installed_apps_cache = json.dumps(apps)
			swagger_settings.save(ignore_permissions=True)
			frappe.db.commit()
			frappe.log_info("Swagger Settings: Successfully cached the list of installed apps.")

	except Exception:
		frappe.log_error(f"Failed to cache installed apps list. Error: {traceback.format_exc()}")