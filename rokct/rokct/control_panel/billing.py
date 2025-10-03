# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from .paystack_controller import PaystackController

@frappe.whitelist()
def save_payment_method(transaction_reference):
    """
    Verifies a Paystack transaction and saves the customer's authorization code
    for future charges.
    """
    paystack_controller = PaystackController()
    verification_result = paystack_controller.verify_transaction_and_get_auth(transaction_reference)

    if not verification_result.get("success"):
        frappe.throw(f"Paystack verification failed: {verification_result.get('message')}")

    auth_data = verification_result.get("authorization")
    customer_email = verification_result.get("customer_email")

    if not all([auth_data, customer_email, auth_data.get("authorization_code")]):
        frappe.throw("Invalid authorization data received from Paystack.")

    try:
        customer = frappe.get_doc("Customer", {"customer_primary_email": customer_email})
        customer.db_set("paystack_authorization_code", auth_data.get("authorization_code"), update_modified=False)

        # Also update card details for user convenience
        customer.db_set("paystack_card_brand", auth_data.get("card_type"), update_modified=False)
        customer.db_set("paystack_last4", auth_data.get("last4"), update_modified=False)

        frappe.db.commit()
        return {"status": "success", "message": "Payment method saved successfully."}

    except frappe.DoesNotExistError:
        frappe.log_error(f"Could not find customer with email: {customer_email}", "Payment Method Error")
        frappe.throw(f"Could not find a customer with the email address {customer_email}.")
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Save Payment Method Failed")
        frappe.throw("An unexpected error occurred while saving the payment method.")

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
    return "Payment retry has been scheduled. You will be notified when it is complete."