# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document


class Competitor(Document):
	pass

@frappe.whitelist()
def get_competitor_map_data(competitor):
	"""
	Retrieves all location data for a given competitor.
	"""
	if not frappe.db.exists("Competitor", competitor):
		return {"status": "error", "message": "Competitor not found"}

	locations = frappe.get_all("Competitor Location",
		filters={"parent": competitor, "parenttype": "Competitor"},
		fields=["location_name", "location_geolocation"]
	)

	return {"status": "success", "data": locations}

@frappe.whitelist()
def save_competitor_map_data(competitor, data):
	"""
	Saves map data (stations, spazas, zones, routes) for a given competitor.
	The data is flattened into the 'Competitor Location' child table.
	"""
	import json

	if not frappe.db.exists("Competitor", competitor):
		return {"status": "error", "message": "Competitor not found"}

	try:
		data = json.loads(data)
		doc = frappe.get_doc("Competitor", competitor)

		# Clear existing map data by removing only map-related locations
		existing_locations = doc.get("office_locations")
		map_locations = []
		if existing_locations:
			for loc in existing_locations:
				if not loc.location_name.startswith(("Station:", "Spaza:", "Zone:", "Route:")):
					map_locations.append(loc)

		# Process and add new data
		# Add stations
		for station in data.get("stations", []):
			map_locations.append({
				"doctype": "Competitor Location",
				"location_name": f"Station:{station.get('name')}",
				"location_geolocation": f'{{"type":"Point","coordinates":[{station.get("lng")},{station.get("lat")}]}}'
			})

		# Add spazas
		for spaza in data.get("spazas", []):
			map_locations.append({
				"doctype": "Competitor Location",
				"location_name": f"Spaza:{spaza.get('name')}",
				"location_geolocation": f'{{"type":"Point","coordinates":[{spaza.get("lng")},{spaza.get("lat")}]}}'
			})

		# Add zones (each point becomes a record)
		for zone in data.get("zones", []):
			for i, point in enumerate(zone.get("path", [])):
				map_locations.append({
					"doctype": "Competitor Location",
					"location_name": f"Zone:{zone.get('name')}:{i}",
					"location_geolocation": f'{{"type":"Point","coordinates":[{point.get("lng")},{point.get("lat")}]}}'
				})

		# Add routes (each point becomes a record)
		for route in data.get("routes", []):
			for i, point in enumerate(route.get("path", [])):
				map_locations.append({
					"doctype": "Competitor Location",
					"location_name": f"Route:{route.get('name')}:{route.get('type')}:{i}",
					"location_geolocation": f'{{"type":"Point","coordinates":[{point.get("lng")},{point.get("lat")}]}}'
				})

		doc.set("office_locations", map_locations)
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
