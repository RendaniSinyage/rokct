import frappe
import json

def execute():
    """
    Seeds the Payment Gateway documents from the legacy `payments` table data.
    This patch is designed to be run on the `juvo.tenant.rokct.ai` site.
    """
    # Site-specific check
    if frappe.local.site != "juvo.tenant.rokct.ai":
        print(f"SKIPPING: Seeding Payment Gateways for site {frappe.local.site}")
        return

    print("\n--- Running Patch: Seeding Payment Gateways ---")

    payment_gateways_data = [
        {"id": 1, "tag": "cash", "active": 1, "sandbox": 0},
        {"id": 2, "tag": "wallet", "active": 1, "sandbox": 0},
        {"id": 3, "tag": "paypal", "active": 0, "sandbox": 0},
        {"id": 4, "tag": "stripe", "active": 0, "sandbox": 0},
        {"id": 5, "tag": "paystack", "active": 0, "sandbox": 0},
        {"id": 6, "tag": "razorpay", "active": 0, "sandbox": 0},
        {"id": 8, "tag": "flutterWave", "active": 0, "sandbox": 0},
        {"id": 9, "tag": "mercado-pago", "active": 0, "sandbox": 0},
        {"id": 10, "tag": "paytabs", "active": 0, "sandbox": 0},
        {"id": 12, "tag": "pay-fast", "active": 1, "sandbox": 1}
    ]

    for gateway_data in payment_gateways_data:
        # Format the name from the tag
        tag = gateway_data.get("tag")
        if tag == "flutterWave":
            gateway_name = "Flutterwave"
        else:
            gateway_name = tag.replace("-", " ").title()

        try:
            if not frappe.db.exists("Payment Gateway", gateway_name):
                pg = frappe.new_doc("Payment Gateway")
                pg.gateway_name = gateway_name
                pg.enabled = gateway_data.get("active")

                # Standard Frappe field for this is 'settings_doctype' but this is a custom app
                # Let's assume a simple structure based on the data.
                # We can't know the exact controller path or settings doctype without more info.

                pg.insert(ignore_permissions=True, docname=gateway_name)
                print(f"SUCCESS: Imported Payment Gateway '{gateway_name}'")
            else:
                # If it exists, update the enabled status as per the SQL data
                frappe.db.set_value("Payment Gateway", gateway_name, "enabled", gateway_data.get("active"))
                print(f"SKIPPED: Payment Gateway '{gateway_name}' already exists. Updated 'enabled' status.")
        except Exception as e:
            # It's possible the DocType or fields are different. This will help debug.
            print(f"ERROR: Failed to import Payment Gateway '{gateway_name}'. Please check DocType and field names. Reason: {e}")

    frappe.db.commit()
    print("\n--- Seeding of Payment Gateways complete ---")