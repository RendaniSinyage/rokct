# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.utils import getdate, nowdate, add_months, add_years
from .paystack_controller import PaystackController

def retry_payment_for_subscription_job(subscription_name, user):
    """
    A background job that attempts to charge a customer for a single subscription renewal.
    Notifies the calling user of the outcome.
    """
    try:
        subscription = frappe.get_doc("Company Subscription", subscription_name)
        plan = frappe.get_doc("Subscription Plan", subscription.plan)
        customer = frappe.get_doc("Customer", subscription.customer)

        if subscription.status != "Grace Period":
            frappe.publish_realtime("show_alert", {"message": f"Subscription {subscription.name} is not in a 'Grace Period' status.", "indicator": "orange"}, user=user)
            return

        paystack_controller = PaystackController()
        payment_result = paystack_controller.charge_customer(
            customer_email=customer.customer_primary_email,
            amount_in_base_unit=plan.cost,
            currency=plan.currency
        )

        if payment_result.get("success"):
            subscription.status = "Active"
            if plan.billing_cycle == 'Month':
                subscription.next_billing_date = add_months(getdate(nowdate()), 1)
            elif plan.billing_cycle == 'Year':
                subscription.next_billing_date = add_years(getdate(nowdate()), 1)
            subscription.save(ignore_permissions=True)
            frappe.db.commit()
            frappe.publish_realtime("show_alert", {"message": f"Payment for {subscription.name} was successful. Status is now 'Active'.", "indicator": "green"}, user=user)
        else:
            # Payment failed again. Notify the user.
            frappe.publish_realtime("show_alert", {"message": f"Payment for {subscription.name} failed again. Reason: {payment_result.get('message')}", "indicator": "red"}, user=user)

    except Exception as e:
        frappe.log_error(f"Failed to retry payment for subscription {subscription_name}: {e}", "Subscription Payment Retry Error")
        frappe.publish_realtime("show_alert", {"message": f"An unexpected error occurred while retrying payment for {subscription_name}. See the Error Log for details.", "indicator": "red"}, user=user)