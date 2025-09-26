# Copyright (c) 2025, ROKCT and contributors
# For license information, please see license.txt

import frappe

def get_context(context):
	context.gmaps_api_key = frappe.conf.get("google_maps_api_key")