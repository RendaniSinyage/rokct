# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import requests

class PaystackController:
    """
    A controller to handle all interactions with the Paystack API.
    """
    def __init__(self):
        self.settings = frappe.get_doc("Paystack Settings")
        self.secret_key = self.settings.get_password("secret_key")
        self.base_url = "https://api.paystack.co"

    def verify_transaction_and_get_auth(self, reference):
        """
        Verifies a transaction using the reference from Paystack's frontend.
        If successful, returns the authorization details.

        :param reference: The transaction reference from Paystack.
        :return: A dictionary with the result.
        """
        if not self.secret_key:
            return {"success": False, "message": "Paystack secret key is not configured."}

        headers = {"Authorization": f"Bearer {self.secret_key}"}
        url = f"{self.base_url}/transaction/verify/{reference}"

        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            data = response.json().get("data", {})

            if data.get("status") == "success" and data.get("authorization"):
                return {
                    "success": True,
                    "authorization": data.get("authorization"),
                    "customer_email": data.get("customer", {}).get("email")
                }
            else:
                return {"success": False, "message": data.get("gateway_response", "Verification failed.")}

        except requests.exceptions.RequestException as e:
            frappe.log_error(f"Paystack API request failed: {e}", "Paystack Integration Error")
            return {"success": False, "message": f"Failed to connect to Paystack: {e}"}
        except Exception as e:
            frappe.log_error(f"An unexpected error occurred during Paystack verification: {e}", "Paystack Integration Error")
            return {"success": False, "message": f"An unexpected error occurred: {e}"}

    def charge_customer(self, customer_email, amount_in_base_unit, currency="USD"):
        """
        Charges a customer using their saved payment token (authorization code) on Paystack.
        """
        if not self.secret_key:
            return {"success": False, "message": "Paystack secret key is not configured."}

        customer = frappe.get_doc("Customer", {"customer_primary_email": customer_email})
        auth_code = customer.get("paystack_authorization_code")
        if not auth_code:
            return {"success": False, "message": f"No Paystack authorization code found for customer {customer.name}."}

        amount_in_kobo = int(amount_in_base_unit * 100)

        headers = {
            "Authorization": f"Bearer {self.secret_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "email": customer_email,
            "amount": amount_in_kobo,
            "authorization_code": auth_code,
            "currency": currency
        }
        url = f"{self.base_url}/transaction/charge_authorization"

        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            response_data = response.json()

            if response_data.get("status") and response_data.get("data", {}).get("status") == "success":
                return {"success": True, "message": "Payment successful."}
            else:
                failure_reason = response_data.get("data", {}).get("gateway_response", "Unknown reason.")
                return {"success": False, "message": f"Payment failed: {failure_reason}"}

        except requests.exceptions.RequestException as e:
            frappe.log_error(f"Paystack API request failed: {e}", "Paystack Integration Error")
            return {"success": False, "message": f"Failed to connect to Paystack: {e}"}
        except Exception as e:
            frappe.log_error(f"An unexpected error occurred during Paystack charge: {e}", "Paystack Integration Error")
            return {"success": False, "message": f"An unexpected error occurred: {e}"}