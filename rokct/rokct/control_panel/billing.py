# This file will contain APIs related to billing and payments.
import frappe
import stripe

@frappe.whitelist()
def save_payment_method(customer_id, payment_method_token):
    """
    Saves a customer's payment method using a token from the frontend.
    """
    # This API should only ever run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")

    # --- Input Validation ---
    if not customer_id or not payment_method_token:
        frappe.throw("Customer ID and Payment Method Token are required.", title="Missing Information")

    if not isinstance(payment_method_token, str) or not payment_method_token.startswith("pm_"):
        frappe.throw("Invalid Payment Method Token format.", title="Invalid Input")

    if not frappe.db.exists("Customer", customer_id):
        frappe.throw(f"Customer '{customer_id}' not found.", title="Not Found")
    # --- End Validation ---

    try:
        # 1. Get Stripe API keys from settings
        settings = frappe.get_doc("Subscription Settings")
        stripe.api_key = settings.get_password("stripe_secret_key")
        if not stripe.api_key:
            frappe.throw("Stripe is not configured. Please set the API keys in Subscription Settings.")

        customer = frappe.get_doc("Customer", customer_id)
        stripe_customer_id = customer.stripe_customer_id

        # 2. Create a Stripe Customer if one doesn't exist
        if not stripe_customer_id:
            stripe_customer = stripe.Customer.create(
                email=customer.email_id,
                name=customer.customer_name,
                description=f"Frappe Customer: {customer.name}",
            )
            stripe_customer_id = stripe_customer.id
            customer.stripe_customer_id = stripe_customer_id
            customer.save(ignore_permissions=True)

        # 3. Attach the payment method to the customer
        stripe.PaymentMethod.attach(
            payment_method_token,
            customer=stripe_customer_id,
        )

        # 4. Set the new payment method as the default for subscriptions
        stripe.Customer.modify(
            stripe_customer_id,
            invoice_settings={"default_payment_method": payment_method_token},
        )

        frappe.db.commit()
        return {"status": "success", "message": "Payment method saved successfully."}

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Save Payment Method Failed")
        frappe.throw(f"An error occurred while saving the payment method: {e}")


@frappe.whitelist()
def reinstate_subscription(subscription_id):
    """
    Reinstates a 'Downgraded' subscription back to its previous plan.
    This is typically called after a user adds a payment method or resolves a billing issue.
    """
    from frappe.utils import nowdate, add_months, add_years

    # This API should only ever run on the control panel.
    if frappe.conf.get("app_role") != "control_panel":
        frappe.throw("This action can only be performed on the control panel.", title="Action Not Allowed")

    # --- Input Validation ---
    if not subscription_id:
        frappe.throw("Subscription ID is required.", title="Missing Information")

    if not frappe.db.exists("Company Subscription", subscription_id):
        frappe.throw(f"Subscription '{subscription_id}' not found.", title="Not Found")
    # --- End Validation ---

    try:
        subscription = frappe.get_doc("Company Subscription", subscription_id)

        if subscription.status != "Downgraded":
            frappe.throw("This subscription is not in a 'Downgraded' state and cannot be reinstated.", title="Action Not Allowed")

        if not subscription.previous_plan:
            frappe.throw("Cannot reinstate subscription because there is no 'Previous Plan' recorded.", title="Missing Data")

        # Reinstate the subscription
        previous_plan_name = subscription.previous_plan
        subscription.plan = previous_plan_name
        subscription.previous_plan = None
        subscription.status = "Active"

        # Recalculate the next billing date
        plan_doc = frappe.get_doc("Subscription Plan", previous_plan_name)
        if plan_doc.billing_cycle == 'Month':
            subscription.next_billing_date = add_months(nowdate(), 1)
        elif plan_doc.billing_cycle == 'Year':
            subscription.next_billing_date = add_years(nowdate(), 1)
        else: # Handle free or one-time plans if necessary
            subscription.next_billing_date = None

        subscription.save(ignore_permissions=True)
        frappe.db.commit()

        return {
            "status": "success",
            "message": f"Subscription reinstated successfully to the '{previous_plan_name}' plan."
        }

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Reinstate Subscription Failed")
        frappe.throw(f"An error occurred while reinstating the subscription: {e}")
