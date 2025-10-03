# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe

@frappe.whitelist()
def retry_billing_for_subscription(subscription_name):
    """
    Enqueues a background job to immediately retry a failed payment for a specific subscription.
    This is intended to be called by an administrator from the UI.
    """
    # We pass the user so the background job can send a real-time notification back.
    frappe.enqueue(
        "rokct.rokct.control_panel.tasks.retry_payment_for_subscription_job",
        queue="short",
        job_name=f"retry-payment-{subscription_name}",
        subscription_name=subscription_name,
        user=frappe.session.user
    )
    return {"status": "success", "message": "Payment retry has been scheduled. You will be notified when it is complete."}