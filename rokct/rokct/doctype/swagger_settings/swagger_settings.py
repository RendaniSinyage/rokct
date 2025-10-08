# Copyright (c) 2024, ROKCT and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document
from rokct.swagger.swagger_generator import generate_swagger_json
import os
import traceback
import logging

# Setup a dedicated logger that is independent of Frappe's context
debug_logger = logging.getLogger('swagger_debug')
handler = logging.FileHandler('/tmp/swagger_debug.log', mode='w')
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
debug_logger.addHandler(handler)
debug_logger.setLevel(logging.INFO)

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
		frappe.log_info("Swagger Generation Enqueued", "Swagger generation job was enqueued by a hook on the control site.")

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
	the apps.txt file, which is a more reliable method in a multi-tenant environment.
	This version includes robust, independent logging to diagnose environment issues.
	"""
	try:
		debug_logger.info("--- Starting get_installed_apps_list ---")

		# Log basic frappe context if available
		try:
			site_name = frappe.local.site
			bench_path = frappe.utils.get_bench_path()
			debug_logger.info(f"Frappe context available. Site: {site_name}, Bench Path: {bench_path}")
		except Exception as e:
			site_name = None
			bench_path = None
			debug_logger.warning(f"Frappe context not fully available: {e}")

		# Manually determine path if frappe context fails
		if not bench_path:
			debug_logger.info("Attempting to manually determine bench path.")
			# Start from the current file's directory and go up
			current_dir = os.path.dirname(__file__)
			debug_logger.info(f"Starting directory: {current_dir}")
			# Go up until we find a 'sites' directory, which indicates the bench root
			for i in range(5): # Limit to 5 levels up to prevent infinite loop
				if "sites" in os.listdir(current_dir):
					bench_path = current_dir
					debug_logger.info(f"Found bench path at: {bench_path}")
					break
				current_dir = os.path.dirname(current_dir)

			if not bench_path:
				debug_logger.error("Could not manually determine bench path.")
				return [] # Return empty if we can't find the path

		# We need the site name, which should be available if the request is coming from a site
		if not site_name:
			# Fallback to trying to get it from the request headers if possible, though this is not standard
			site_name = frappe.request.headers.get('X-Frappe-Site-Name') if hasattr(frappe, 'request') else None
			if site_name:
				debug_logger.info(f"Got site name from request headers: {site_name}")
			else:
				debug_logger.error("Could not determine site name.")
				return []

		apps_txt_path = os.path.join(bench_path, "sites", site_name, "apps.txt")
		debug_logger.info(f"Constructed apps.txt path: {apps_txt_path}")

		if os.path.exists(apps_txt_path):
			debug_logger.info("apps.txt file found. Reading contents.")
			with open(apps_txt_path, "r") as f:
				apps = [line.strip() for line in f if line.strip()]
				debug_logger.info(f"Apps found: {apps}")
				return apps
		else:
			debug_logger.warning("apps.txt file not found at the constructed path.")

		debug_logger.warning("Falling back to frappe.get_installed_apps().")
		return frappe.get_installed_apps()

	except Exception as e:
		debug_logger.error(f"A critical error occurred in get_installed_apps_list: {traceback.format_exc()}")
		return [] # Return an empty list on critical failure