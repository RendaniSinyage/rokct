import frappe
import os
import json

def execute():
    """
    Seeds the Subscription Plan table from individual JSON files, ensuring all
    dependent 'Item' documents are created first.
    This patch is hyper-verbose to prevent silent failures.
    """
    print("\n--- Running Patch V2: Seeding Subscription Plans with Dependencies ---")

    app_path = frappe.get_app_path("rokct")
    fixtures_path = os.path.join(app_path, "rokct", "fixtures", "Subscription_Plan")

    if not os.path.exists(fixtures_path):
        print(f"ERROR: Fixture directory not found at {fixtures_path}. Aborting.")
        return

    plan_files = [f for f in os.listdir(fixtures_path) if f.endswith('.json')]

    if not plan_files:
        print("No subscription plan JSON files found to seed.")
        return

    for plan_file in plan_files:
        plan_name_from_file = os.path.splitext(plan_file)[0]
        print(f"\n--- Processing Plan: {plan_name_from_file} ---")

        try:
            file_path = os.path.join(fixtures_path, plan_file)
            with open(file_path, 'r') as f:
                data = json.load(f)

            plan_doc_name = data.get("plan_name")
            item_name = data.get("item")

            if not plan_doc_name or not item_name:
                print(f"ERROR: Plan '{plan_name_from_file}' is missing 'plan_name' or 'item' field in JSON. Skipping.")
                continue

            # Step 1: Ensure the dependent Item exists
            if not frappe.db.exists("Item", item_name):
                print(f"INFO: Dependent Item '{item_name}' not found. Creating it now...")
                try:
                    item = frappe.new_doc("Item")
                    item.item_code = item_name
                    item.item_name = item_name
                    item.item_group = "Services"  # A sensible default
                    item.is_stock_item = 0
                    item.insert(ignore_permissions=True)
                    print(f"SUCCESS: Created dependent Item '{item_name}'.")
                except Exception as e:
                    print(f"ERROR: Failed to create dependent Item '{item_name}'. Subscription plan will likely fail. Reason: {e}")
                    frappe.log_error(f"Failed to create dependent Item {item_name}", "Subscription Plan Seeder V2")
                    continue # Skip to next plan if item creation fails

            # Step 2: Create the Subscription Plan
            if not frappe.db.exists("Subscription Plan", plan_doc_name):
                print(f"INFO: Subscription Plan '{plan_doc_name}' does not exist. Creating it now...")
                new_plan = frappe.new_doc("Subscription Plan")
                new_plan.update(data)
                new_plan.insert(ignore_permissions=True)
                print(f"SUCCESS: Imported Subscription Plan '{plan_doc_name}'.")
            else:
                print(f"SKIPPED: Subscription Plan '{plan_doc_name}' already exists.")

        except Exception as e:
            print(f"FATAL ERROR: An unexpected error occurred while processing '{plan_name_from_file}'. Reason: {e}")
            frappe.log_error(f"Failed to import Subscription Plan {plan_name_from_file}", "Subscription Plan Seeder V2")

    frappe.db.commit()
    print("\n--- Subscription Plan Seeder V2 complete ---")