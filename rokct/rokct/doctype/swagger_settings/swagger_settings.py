# Copyright (c) 2024, Omkar Darves and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document
from rokct.swagger.swagger_generator import generate_swagger_json

class SwaggerSettings(Document):
	pass

def run_swagger_generation_on_control_site():
	"""
	This function is called by hooks. It checks if the site is a control panel
	and then runs the swagger generation.
	"""
	if frappe.get_conf().get("app_role") == "control_panel":
		try:
			generate_swagger_json()
			frappe.db.commit()
			frappe.log_error("Swagger Generation Triggered", "Swagger generation was successfully triggered by a hook on the control site.")
		except Exception as e:
			frappe.log_error("Swagger Generation Failed", f"An error occurred during swagger generation triggered by a hook: {str(e)}")

@frappe.whitelist()
def get_app_role():
	"""
	Returns the app_role from the site config to the client-side script.
	"""
	return frappe.get_conf().get("app_role")
