import frappe
import json
import requests
from frappe.model.document import Document

@frappe.whitelist(allow_guest=True)
def get_payment_gateways():
    """
    Retrieves a list of active payment gateways, formatted for frontend compatibility.
    """
    gateways = frappe.get_list(
        "Payment Gateway",
        filters={"enabled": 1},
        fields=["name", "gateway_controller", "is_sandbox", "creation", "modified"]
    )

    formatted_gateways = []
    for gw in gateways:
        formatted_gateways.append({
            "id": gw.name,
            "tag": gw.gateway_controller,
            "sandbox": bool(gw.is_sandbox),
            "active": True,
            "created_at": gw.creation.strftime('%Y-%m-%d %H:%M:%S') + 'Z',
            "updated_at": gw.modified.strftime('%Y-%m-%d %H:%M:%S') + 'Z',
        })

    return formatted_gateways


@frappe.whitelist(allow_guest=True)
def get_payment_gateway(id: str):
    """
    Retrieves a single active payment gateway.
    """
    gw = frappe.db.get_value(
        "Payment Gateway",
        filters={"name": id, "enabled": 1},
        fieldname=["name", "gateway_controller", "is_sandbox", "creation", "modified"],
        as_dict=True
    )

    if not gw:
        frappe.throw("Payment Gateway not found or not active.")

    return {
        "id": gw.name,
        "tag": gw.gateway_controller,
        "sandbox": bool(gw.is_sandbox),
        "active": True,
        "created_at": gw.creation.strftime('%Y-%m-%d %H:%M:%S') + 'Z',
        "updated_at": gw.modified.strftime('%Y-%m-%d %H:%M:%S') + 'Z',
    }


@frappe.whitelist()
def initiate_flutterwave_payment(order_id: str):
    """
    Initiates a payment with Flutterwave for a given order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to make a payment.")

    try:
        order = frappe.get_doc("Order", order_id)
        if order.owner != user:
            frappe.throw("You are not authorized to pay for this order.", frappe.PermissionError)

        if order.payment_status == "Paid":
            frappe.throw("This order has already been paid for.")

        flutterwave_settings = frappe.get_doc("Flutterwave Settings")
        if not flutterwave_settings.enabled:
            frappe.throw("Flutterwave payments are not enabled.")

        # Prepare the request to Flutterwave
        tx_ref = f"{order.name}-{frappe.utils.now_datetime().strftime('%Y%m%d%H%M%S')}"

        # Get customer details
        customer = frappe.get_doc("User", user)

        payload = {
            "tx_ref": tx_ref,
            "amount": order.grand_total,
            "currency": frappe.db.get_single_value("System Settings", "currency"),
            "redirect_url": frappe.utils.get_url_to_method("rokct.paas.api.flutterwave_callback"),
            "customer": {
                "email": customer.email,
                "phonenumber": customer.phone,
                "name": customer.get_fullscreen(),
            },
            "customizations": {
                "title": f"Payment for Order {order.name}",
                "logo": frappe.get_website_settings("website_logo")
            }
        }

        headers = {
            "Authorization": f"Bearer {flutterwave_settings.get_password('secret_key')}",
            "Content-Type": "application/json"
        }

        # Make the request to Flutterwave
        response = requests.post("https://api.flutterwave.com/v3/payments", json=payload, headers=headers)
        response.raise_for_status()
        response_data = response.json()

        if response_data.get("status") == "success":
            # Update the order with the transaction reference
            order.custom_payment_transaction_id = tx_ref
            order.save(ignore_permissions=True)
            frappe.db.commit()

            return {"payment_url": response_data["data"]["link"]}
        else:
            frappe.log_error(f"Flutterwave initiation failed: {response_data.get('message')}", "Flutterwave Error")
            frappe.throw("Failed to initiate payment with Flutterwave.")

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Flutterwave Payment Initiation Failed")
        frappe.throw(f"An error occurred during payment initiation: {e}")


@frappe.whitelist(allow_guest=True)
def flutterwave_callback():
    """
    Handles the callback from Flutterwave after a payment attempt.
    """
    args = frappe.request.args
    status = args.get("status")
    tx_ref = args.get("tx_ref")
    transaction_id = args.get("transaction_id")

    flutterwave_settings = frappe.get_doc("Flutterwave Settings")
    success_url = flutterwave_settings.success_redirect_url or "/payment-success"
    failure_url = flutterwave_settings.failure_redirect_url or "/payment-failed"

    if not tx_ref:
        frappe.local.response["type"] = "redirect"
        frappe.local.response["location"] = failure_url + "?reason=tx_ref_missing"
        return

    try:
        order_id = tx_ref.split('-')[0]
        order = frappe.get_doc("Order", order_id)

        if status == "successful":
            headers = {"Authorization": f"Bearer {flutterwave_settings.get_password('secret_key')}"}
            verify_url = f"https://api.flutterwave.com/v3/transactions/{transaction_id}/verify"
            response = requests.get(verify_url, headers=headers)
            response.raise_for_status()
            verification_data = response.json()

            if (verification_data.get("status") == "success" and
                verification_data["data"]["tx_ref"] == tx_ref and
                verification_data["data"]["amount"] >= order.grand_total):

                order.payment_status = "Paid"
                order.custom_payment_transaction_id = transaction_id
                order.save(ignore_permissions=True)
                frappe.db.commit()

                frappe.local.response["type"] = "redirect"
                frappe.local.response["location"] = success_url
                return

            else:
                order.payment_status = "Failed"
                order.save(ignore_permissions=True)
                frappe.db.commit()
                frappe.log_error(f"Flutterwave callback verification failed for order {order_id}. Data: {verification_data}", "Flutterwave Error")
                frappe.local.response["type"] = "redirect"
                frappe.local.response["location"] = failure_url + "?reason=verification_failed"
                return

        else: # Status is 'cancelled' or 'failed'
            order.payment_status = "Failed"
            order.save(ignore_permissions=True)
            frappe.db.commit()
            frappe.local.response["type"] = "redirect"
            frappe.local.response["location"] = failure_url + f"?reason={status}"
            return

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Flutterwave Callback Failed")
        frappe.local.response["type"] = "redirect"
        frappe.local.response["location"] = failure_url + "?reason=internal_error"

@frappe.whitelist()
def get_payfast_settings():
    """
    Returns the PayFast settings.
    """
    payfast_settings = frappe.get_doc("Payment Gateway", "PayFast")
    settings = {s.key: s.value for s in payfast_settings.settings}
    return {
        "merchant_id": settings.get("merchant_id"),
        "merchant_key": settings.get("merchant_key"),
        "pass_phrase": settings.get("pass_phrase"),
        "is_sandbox": payfast_settings.is_sandbox,
        "success_redirect_url": payfast_settings.success_redirect_url or "/payment-success",
        "failure_redirect_url": payfast_settings.failure_redirect_url or "/payment-failed"
    }


@frappe.whitelist(allow_guest=True)
def handle_payfast_callback():
    """
    Handles the PayFast payment callback.
    """
    data = frappe.form_dict

    transaction_id = data.get("m_payment_id")
    if not transaction_id:
        frappe.log_error("PayFast callback received without m_payment_id", data)
        return

    transaction = frappe.get_doc("Transaction", transaction_id)

    payfast_settings = frappe.get_doc("Payment Gateway", "PayFast")
    settings = {s.key: s.value for s in payfast_settings.settings}

    passphrase = settings.get("pass_phrase")

    pf_param_string = ""
    for key in sorted(data.keys()):
        if key != 'signature':
            pf_param_string += f"{key}={data[key]}&"

    pf_param_string = pf_param_string[:-1]

    if passphrase:
         pf_param_string += f"&passphrase={passphrase}"

    signature = frappe.utils.md5_hash(pf_param_string)

    if signature != data.get("signature"):
        frappe.log_error("PayFast callback signature mismatch", data)
        transaction.status = "Error"
        transaction.save(ignore_permissions=True)
        return

    if data.get("payment_status") == "COMPLETE":
        transaction.status = "Completed"
        order = frappe.get_doc("Order", transaction.reference_name)
        order.status = "Paid"
        order.save(ignore_permissions=True)
    elif data.get("payment_status") == "FAILED":
        transaction.status = "Failed"
    else:
        transaction.status = "Cancelled"

    transaction.save(ignore_permissions=True)


@frappe.whitelist()
def process_payfast_token_payment(order_id: str, token: str):
    """
    Processes a payment using a saved PayFast token.
    """
    frappe.throw("Token payment not yet implemented.")


@frappe.whitelist()
def save_payfast_card(token: str, card_details: str):
    """
    Saves a PayFast card token.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to save a card.")

    if isinstance(card_details, str):
        card_details = json.loads(card_details)

    frappe.get_doc({
        "doctype": "Saved Card",
        "user": user,
        "token": token,
        "last_four": card_details.get("last_four"),
        "card_type": card_details.get("card_type"),
        "expiry_date": card_details.get("expiry_date"),
        "card_holder_name": card_details.get("card_holder_name")
    }).insert(ignore_permissions=True)
    return {"status": "success", "message": "Card saved successfully."}


@frappe.whitelist()
def get_saved_payfast_cards():
    """
    Retrieves a list of saved cards for the current user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your saved cards.")

    return frappe.get_all(
        "Saved Card",
        filters={"user": user},
        fields=["name", "last_four", "card_type", "expiry_date"]
    )


@frappe.whitelist()
def delete_payfast_card(card_name: str):
    """
    Deletes a saved card.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to delete a card.")

    card = frappe.get_doc("Saved Card", card_name)
    if card.user != user:
        frappe.throw("You are not authorized to delete this card.", frappe.PermissionError)

    frappe.delete_doc("Saved Card", card_name, ignore_permissions=True)
    return {"status": "success", "message": "Card deleted successfully."}

@frappe.whitelist(allow_guest=True)
def handle_paypal_callback():
    """
    Handles the PayPal payment callback.
    """
    data = frappe.form_dict

    token = data.get("token")
    if not token:
        frappe.log_error("PayPal callback received without token", data)
        return

    transaction = frappe.get_doc("Transaction", {"transaction_id": token})

    paypal_settings_doc = frappe.get_doc("Payment Gateway", "PayPal")
    settings = {s.key: s.value for s in paypal_settings_doc.settings}
    success_url = paypal_settings_doc.success_redirect_url or "/payment-success"
    failure_url = paypal_settings_doc.failure_redirect_url or "/payment-failed"

    auth_url = "https://api-m.sandbox.paypal.com/v1/oauth2/token" if settings.get("paypal_mode") == "sandbox" else "https://api-m.paypal.com/v1/oauth2/token"
    client_id = settings.get("paypal_sandbox_client_id") if settings.get("paypal_mode") == "sandbox" else settings.get("paypal_live_client_id")
    client_secret = settings.get("paypal_sandbox_client_secret") if settings.get("paypal_mode") == "sandbox" else settings.get("paypal_live_client_secret")

    auth_response = requests.post(
        auth_url,
        auth=(client_id, client_secret),
        data={"grant_type": "client_credentials"}
    )
    auth_response.raise_for_status()
    access_token = auth_response.json()["access_token"]

    order_url = f"https://api-m.sandbox.paypal.com/v2/checkout/orders/{token}" if settings.get("paypal_mode") == "sandbox" else f"https://api-m.paypal.com/v2/checkout/orders/{token}"

    order_response = requests.get(
        order_url,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        }
    )
    order_response.raise_for_status()
    paypal_order = order_response.json()

    if paypal_order.get("status") == "COMPLETED":
        transaction.status = "Completed"
        order = frappe.get_doc("Order", transaction.reference_name)
        order.status = "Paid"
        order.save(ignore_permissions=True)
        transaction.save(ignore_permissions=True)
        frappe.local.response["type"] = "redirect"
        frappe.local.response["location"] = success_url
    else:
        transaction.status = "Failed"
        transaction.save(ignore_permissions=True)
        frappe.local.response["type"] = "redirect"
        frappe.local.response["location"] = failure_url


@frappe.whitelist()
def initiate_paypal_payment(order_id: str):
    """
    Initiates a PayPal payment for a specific order.
    """
    order = frappe.get_doc("Order", order_id)

    paypal_settings_doc = frappe.get_doc("Payment Gateway", "PayPal")
    settings = {s.key: s.value for s in paypal_settings_doc.settings}
    success_url = paypal_settings_doc.success_redirect_url or f"{frappe.utils.get_url()}/api/method/rokct.paas.api.handle_paypal_callback"
    failure_url = paypal_settings_doc.failure_redirect_url or f"{frappe.utils.get_url()}/api/method/rokct.paas.api.handle_paypal_callback"


    auth_url = "https://api-m.sandbox.paypal.com/v1/oauth2/token" if settings.get("paypal_mode") == "sandbox" else "https://api-m.paypal.com/v1/oauth2/token"
    client_id = settings.get("paypal_sandbox_client_id") if settings.get("paypal_mode") == "sandbox" else settings.get("paypal_live_client_id")
    client_secret = settings.get("paypal_sandbox_client_secret") if settings.get("paypal_mode") == "sandbox" else settings.get("paypal_live_client_secret")

    auth_response = requests.post(
        auth_url,
        auth=(client_id, client_secret),
        data={"grant_type": "client_credentials"}
    )
    auth_response.raise_for_status()
    access_token = auth_response.json()["access_token"]

    order_url = "https://api-m.sandbox.paypal.com/v2/checkout/orders" if settings.get("paypal_mode") == "sandbox" else "https://api-m.paypal.com/v2/checkout/orders"

    order_payload = {
        "intent": "CAPTURE",
        "purchase_units": [
            {
                "amount": {
                    "currency_code": order.currency,
                    "value": str(order.total_price)
                }
            }
        ],
        "payment_source": {
            "paypal": {
                "experience_context": {
                    "return_url": success_url,
                    "cancel_url": failure_url
                }
            }
        }
    }

    order_response = requests.post(
        order_url,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        },
        json=order_payload
    )
    order_response.raise_for_status()
    paypal_order = order_response.json()

    frappe.get_doc({
        "doctype": "Transaction",
        "reference_doctype": "Order",
        "reference_name": order.name,
        "transaction_id": paypal_order["id"],
        "amount": order.total_price,
        "status": "Pending"
    }).insert(ignore_permissions=True)

    approval_link = next((link["href"] for link in paypal_order["links"] if link["rel"] == "approve"), None)

    if not approval_link:
        frappe.throw("Could not find PayPal approval link.")

    return {"redirect_url": approval_link}


@frappe.whitelist()
def initiate_paystack_payment(order_id: str):
    """
    Initiates a PayStack payment for a specific order.
    """
    order = frappe.get_doc("Order", order_id)

    paystack_settings = frappe.get_doc("Payment Gateway", "PayStack")
    settings = {s.key: s.value for s in paystack_settings.settings}

    headers = {
        "Authorization": f"Bearer {settings.get('paystack_sk')}",
        "Content-Type": "application/json"
    }

    body = {
        "email": frappe.session.user,
        "amount": order.total_price * 100,
        "currency": order.currency,
        "callback_url": f"{frappe.utils.get_url()}/api/method/rokct.paas.api.handle_paystack_callback"
    }

    response = requests.post("https://api.paystack.co/transaction/initialize", headers=headers, json=body)
    response.raise_for_status()
    paystack_data = response.json()

    # Create a new transaction
    frappe.get_doc({
        "doctype": "Transaction",
        "reference_doctype": "Order",
        "reference_name": order.name,
        "transaction_id": paystack_data["data"]["reference"],
        "amount": order.total_price,
        "status": "Pending"
    }).insert(ignore_permissions=True)

    return {"redirect_url": paystack_data["data"]["authorization_url"]}

@frappe.whitelist(allow_guest=True)
def handle_paystack_callback():
    """
    Handles the PayStack payment callback.
    """
    data = frappe.form_dict
    reference = data.get("reference")

    if not reference:
        frappe.log_error("PayStack callback received without reference", data)
        return

    paystack_settings = frappe.get_doc("Payment Gateway", "PayStack")
    settings = {s.key: s.value for s in paystack_settings.settings}

    headers = {
        "Authorization": f"Bearer {settings.get('paystack_sk')}",
    }

    response = requests.get(f"https://api.paystack.co/transaction/verify/{reference}", headers=headers)
    response.raise_for_status()
    paystack_data = response.json()

    if paystack_data["data"]["status"] == "success":
        transaction = frappe.get_doc("Transaction", {"transaction_id": reference})
        transaction.status = "Completed"
        transaction.save(ignore_permissions=True)

        order = frappe.get_doc("Order", transaction.reference_name)
        order.status = "Paid"
        order.save(ignore_permissions=True)
    else:
        transaction = frappe.get_doc("Transaction", {"transaction_id": reference})
        transaction.status = "Failed"
        transaction.save(ignore_permissions=True)

@frappe.whitelist(allow_guest=True)
def log_payment_payload(payload):
    """
    Logs a payment payload.
    """
    frappe.get_doc({
        "doctype": "Payment Payload",
        "payload": payload
    }).insert(ignore_permissions=True)
    return {"status": "success"}

@frappe.whitelist(allow_guest=True)
def handle_stripe_webhook():
    """
    Handles the Stripe payment webhook.
    """
    # TODO: Implement Stripe webhook logic
    return {"status": "success"}