# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document


class Competitor(Document):
	pass

@frappe.whitelist()
def get_competitor_map_data(competitor):
	"""
	Retrieves structured map data for a given competitor.
	"""
	if not frappe.db.exists("Competitor", competitor):
		return {"status": "error", "message": "Competitor not found"}

	doc = frappe.get_doc("Competitor", competitor)

	return {
		"status": "success",
		"data": {
			"locations": doc.get("office_locations"),
			"zones": doc.get("zones"),
			"routes": doc.get("routes")
		}
	}

@frappe.whitelist()
def save_competitor_map_data(competitor, data):
	"""
	Saves structured map data to the competitor's child tables.
	"""
	import json

	if not frappe.db.exists("Competitor", competitor):
		return {"status": "error", "message": "Competitor not found"}

	try:
		data = json.loads(data)
		doc = frappe.get_doc("Competitor", competitor)

		# Update locations (stations/spazas)
		doc.set("office_locations", [])
		for loc in data.get("locations", []):
			doc.append("office_locations", {
				"location_type": loc.get("type"),
				"location_name": loc.get("name"),
				"location_geolocation": f'{{"type":"Point","coordinates":[{loc.get("lng")},{loc.get("lat")}]}}'
			})

		# Update zones
		doc.set("zones", [])
		for zone in data.get("zones", []):
			doc.append("zones", {
				"zone_name": zone.get("name"),
				"zone_path": json.dumps(zone.get("path"))
			})

		# Update routes
		doc.set("routes", [])
		for route in data.get("routes", []):
			doc.append("routes", {
				"route_name": route.get("name"),
				"route_type": route.get("type"),
				"route_path": json.dumps(route.get("path"))
			})

		doc.save(ignore_permissions=True)
		frappe.db.commit()

		return {"status": "success"}

	except Exception as e:
		frappe.log_error(frappe.get_traceback(), "Save Competitor Map Data Error")
		return {"status": "error", "message": str(e)}

def get_dashboard_data(data):
	"""
	Adds a custom "Tools" card to the Competitor dashboard.
	"""
	data["transactions"].append(
		{
			"label": "Tools",
			"items": [
				{
					"type": "page",
					"name": "competitor-analyzer",
					"label": "Competitor Map Analyzer",
					"description": "Analyze competitor locations and routes.",
				}
			],
		}
	)
	return data
