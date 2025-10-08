# Copyright (c) 2024, ROKCT and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document
from rokct.swagger.swagger_generator import generate_swagger_json

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
		frappe.throw(__("Swagger generation can only be triggered from the control site."), title="Not Permitted")

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
	"""
	try:
		site_path = frappe.get_site_path()
		apps_txt_path = os.path.join(site_path, "apps.txt")

		if os.path.exists(apps_txt_path):
			with open(apps_txt_path, "r") as f:
				apps = [line.strip() for line in f if line.strip()]
				return apps
		return frappe.get_installed_apps() # Fallback
	except Exception:
		frappe.log_error(f"Could not read apps.txt, falling back to frappe.get_installed_apps. Error: {traceback.format_exc()}")
		return frappe.get_installed_apps() # Fallback