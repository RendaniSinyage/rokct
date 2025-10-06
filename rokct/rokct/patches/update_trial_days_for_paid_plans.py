import frappe

def execute():
    """
    Sets 'trial_period_days' to 14 for all non-free Subscription Plans.
    """
    frappe.log("Running patch: update_trial_days_for_paid_plans", "Patch Log")

    # Get all subscription plans that are not free
    paid_plans = frappe.get_all(
        "Subscription Plan",
        filters={"cost": [">", 0]},
        fields=["name"]
    )

    if not paid_plans:
        frappe.log("No paid subscription plans found to update.", "Patch Log")
        return

    updated_plans = []
    for plan in paid_plans:
        try:
            frappe.db.set_value("Subscription Plan", plan.name, "trial_period_days", 14)
            updated_plans.append(plan.name)
        except Exception as e:
            frappe.log_error(f"Failed to update trial days for plan {plan.name}: {e}", "Patch Error")

    if updated_plans:
        frappe.log(f"Successfully set 'trial_period_days' to 14 for the following plans: {', '.join(updated_plans)}", "Patch Log")

    frappe.db.commit()
    print("--- Trial days patch applied successfully ---")