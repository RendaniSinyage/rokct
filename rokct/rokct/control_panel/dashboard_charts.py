import frappe
from frappe.utils import nowdate, add_days

def get_new_subscriptions_chart_data():
    """
    Returns data for the "New Subscriptions This Month" chart.
    """
    # This function should only run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        return {
            "labels": [],
            "datasets": []
        }

    # Get data for the last 30 days
    from_date = add_days(nowdate(), -30)

    data = frappe.db.sql(f"""
        SELECT
            DATE(creation) as date,
            COUNT(*) as count
        FROM `tabCompany Subscription`
        WHERE creation >= '{from_date}'
        GROUP BY DATE(creation)
        ORDER BY DATE(creation)
    """, as_dict=1)

    # Prepare data for the chart
    labels = []
    values = []

    # Create a dictionary for quick lookups
    data_dict = {d.date.strftime('%Y-%m-%d'): d.count for d in data}

    # Populate labels and values for the last 30 days
    for i in range(30):
        date = add_days(from_date, i)
        date_str = date.strftime('%Y-%m-%d')
        labels.append(date_str)
        values.append(data_dict.get(date_str, 0))

    return {
        "labels": labels,
        "datasets": [
            {
                "name": "New Subscriptions",
                "values": values
            }
        ]
    }

