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

@frappe.whitelist()
def purchase_add_on(add_on_name: str, customer_email: str):
    """
    Handles the purchase of a single add-on, including eligibility checks and payment.
    Called by a tenant site on behalf of a user.
    """
    # Security check: This should only run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")

    if not all([add_on_name, customer_email]):
        frappe.throw("Add-on Name and Customer Email are required.", title="Missing Information")

    try:
        # 1. Get the relevant documents
        add_on = frappe.get_doc("Add-on", add_on_name)
        customer = frappe.get_doc("Customer", {"customer_primary_email": customer_email})
        subscription = frappe.get_doc("Company Subscription", {"customer": customer.name})

        # 2. Check eligibility
        eligible_plans = [plan.subscription_plan for plan in add_on.get("eligible_plans", [])]
        if eligible_plans and subscription.plan not in eligible_plans:
            frappe.throw(
                f"Your current plan '{subscription.plan}' is not eligible to purchase the '{add_on.add_on_name}' add-on.",
                title="Upgrade Required"
            )

        # 3. Process payment for one-time add-ons
        if add_on.billing_type == "One-time":
            paystack_controller = PaystackController()
            payment_result = paystack_controller.charge_customer(customer_email, add_on.cost, "USD")

            if not payment_result.get("success"):
                raise frappe.ValidationError(f"Payment failed: {payment_result.get('message')}")

        # 4. Add the add-on to the subscription
        for purchased in subscription.get("purchased_add_ons", []):
            if purchased.add_on == add_on_name and add_on.billing_type == "Recurring":
                frappe.throw(f"You have already subscribed to the '{add_on_name}' recurring add-on.", title="Already Subscribed")
        
        subscription.append("purchased_add_ons", {
            "add_on": add_on_name,
            "purchase_date": frappe.utils.nowdate()
        })
        
        subscription.save(ignore_permissions=True)
        frappe.db.commit()

        return {"status": "success", "message": f"Successfully purchased the '{add_on.add_on_name}' add-on."}

    except frappe.DoesNotExistError:
        frappe.log_error(frappe.get_traceback(), "Add-on Purchase Failed")
        frappe.throw("Could not find one of the required records (Customer, Subscription, or Add-on).", title="Not Found")
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), f"Add-on Purchase Failed for {customer_email}")
        frappe.throw(f"An unexpected error occurred during the purchase: {e}")