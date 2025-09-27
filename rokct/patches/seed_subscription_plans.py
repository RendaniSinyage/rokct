import frappe
import os
import json

def execute():
    """
    Seeds the Subscription Plan table from individual JSON files in a directory.
    This patch is designed to be hyper-verbose for clear installation logging.
    """
    print("\n--- Running Patch: Seeding Subscription Plans ---")

    app_path = frappe.get_app_path("rokct")
    fixtures_path = os.path.join(app_path, "rokct", "fixtures", "Subscription_Plan")

    if not os.path.exists(fixtures_path):
        print(f"ERROR: Fixture directory not found at {fixtures_path}")
        return

    plan_files = [f for f in os.listdir(fixtures_path) if f.endswith('.json')]

    if not plan_files:
        print("No subscription plan JSON files found to seed.")
        return

    for plan_file in plan_files:
        plan_name = os.path.splitext(plan_file)[0]
        try:
            if not frappe.db.exists("Subscription Plan", plan_name):
                file_path = os.path.join(fixtures_path, plan_file)
                with open(file_path, 'r') as f:
                    data = json.load(f)

                new_plan = frappe.new_doc("Subscription Plan")
                new_plan.update(data)
                new_plan.insert(ignore_permissions=True)
                print(f"SUCCESS: Imported Subscription Plan '{plan_name}'")
            else:
                print(f"SKIPPED: Subscription Plan '{plan_name}' already exists.")
        except Exception as e:
            print(f"ERROR: Failed to import Subscription Plan '{plan_name}'. Reason: {e}")
            frappe.log_error(f"Failed to import Subscription Plan {plan_name}: {e}", "Subscription Plan Seeder Error")

    frappe.db.commit()
    print("\n--- Subscription Plan seeding complete ---")