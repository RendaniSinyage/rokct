import frappe

def execute():
    # Add paas_plan field
    if not frappe.db.has_column("Company Subscription", "paas_plan"):
        frappe.db.add_column("Company Subscription", "paas_plan", "Check")

    # Add migration_approved field
    if not frappe.db.has_column("Company Subscription", "migration_approved"):
        frappe.db.add_column("Company Subscription", "migration_approved", "Check")

