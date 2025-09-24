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

