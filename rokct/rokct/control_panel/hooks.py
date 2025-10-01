import frappe

def handle_customer_deletion(doc, method):
    """
    When a Customer is deleted, find their subscription and enqueue site deletion.
    """
    if not doc.name:
        return

    # Find the subscription linked to this customer
    subscription_name = frappe.db.get_value("Company Subscription", {"customer": doc.name}, "name")

    if not subscription_name:
        frappe.log_message(
            title="No Subscription Found for Customer",
            message=f"Customer {doc.name} was deleted, but no matching company subscription was found. No site will be deleted."
        )
        return

    subscription = frappe.get_doc("Company Subscription", subscription_name)
    if subscription and subscription.site_name:
        frappe.enqueue(
            "rokct.rokct.control_panel.tasks.drop_tenant_site",
            queue="long",
            timeout=600,
            site_name=subscription.site_name
        )
        frappe.log_message(
            title="Site Deletion Enqueued",
            message=f"Customer {doc.name} was deleted. Site deletion for {subscription.site_name} has been scheduled."
        )
    else:
        frappe.log_error(
            title="Site Deletion Failed",
            message=f"Customer {doc.name} was deleted, but could not find a valid site name on subscription {subscription_name}."
        )