# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import json
import os

@frappe.whitelist(allow_guest=True)
def generate_swagger_json():
    """
    Generates a simple test Swagger JSON to verify which script is being executed.
    """
    frappe_bench_dir = frappe.utils.get_bench_path()

    # Define a simple, minimal Swagger JSON with a unique marker
    test_swagger = {
        "openapi": "3.0.0",
        "info": {
            "title": "Test from Rokct App",
            "version": "1.0.0"
        },
        "source": "rokct_app", # This is the unique marker
        "paths": {}
    }

    # Define the output path
    output_path = os.path.join(frappe_bench_dir, "apps", "swagger", "swagger", "www", "swagger-full.json")

    # Ensure the directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Write the test file
    with open(output_path, "w") as f:
        json.dump(test_swagger, f, indent=4)

    frappe.msgprint("Successfully generated a test swagger-full.json from the ROKCT app.")