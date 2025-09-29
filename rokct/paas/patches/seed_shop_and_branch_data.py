import frappe
import json

def execute():
    # Site-specific check
    if frappe.local.site != "juvo.tenant.rokct.ai":
        print(f"SKIPPING: Seeding Shops and Branches for site {frappe.local.site}")
        return

    print("\n--- Running Patch: Seeding Shops and Branches ---")

    # Shops data extracted from shops.sql
    shops_data = [
        {
            "id": 504, "slug": "kfc-musina-cbd-504", "uuid": "a9fc9f86-08b8-445c-9b85-9daa56366c89", "user_id": 109, "tax": 0.00, "percentage": 15,
            "location": '{"latitude":"-22.3568125","longitude":"30.03256249999999"}', "phone": "27790345401", "show_type": 1, "open": 1, "visibility": 0,
            "background_img": "https://s3.juvo.app/public/images/shops/background/101-1714398279.webp", "logo_img": "https://s3.juvo.app/public/images/shops/logo/101-1722718503.webp",
            "min_amount": 50, "status": "approved", "type": None, "status_note": "approved", "delivery_time": '{"from":"35","to":"60","type":"minute"}',
            "price": 0, "price_per_km": 0, "service_fee": 0, "verify": 1, "order_payment": "before", "new_order_after_payment": 0, "name": "KFC Musina CBD"
        },
        {
            "id": 505, "slug": "nandos-505", "uuid": "2be73dce-f8a9-4acc-99c3-5c8d862910f2", "user_id": 110, "tax": 0.00, "percentage": 15,
            "location": '{"latitude":"-22.340539864424997","longitude":"30.041396928838118"}', "phone": "27790345401", "show_type": 1, "open": 1, "visibility": 0,
            "background_img": "https://s3.juvo.app/public/images/shops/background/101-1678456953.webp", "logo_img": "https://s3.juvo.app/public/images/shops/logo/101-1722720027.webp",
            "min_amount": 50, "status": "approved", "type": None, "status_note": "approved", "delivery_time": '{"from":"35","to":"60","type":"minute"}',
            "price": 0, "price_per_km": 0, "service_fee": 0, "verify": 1, "order_payment": "before", "new_order_after_payment": 0, "name": "Nandos"
        },
        {
            "id": 9000, "slug": "bwi-studios-9000", "uuid": "b7593635-00dd-4d27-b62d-45f2a53158a3", "user_id": 118, "tax": 0.00, "percentage": 15,
            "location": '{"latitude":"-22.3381123","longitude":"30.0122431"}', "phone": "27790345401", "show_type": 1, "open": 1, "visibility": 0,
            "background_img": "https://s3.juvo.app/public/images/shops/background/101-1691404383.webp", "logo_img": "https://s3.juvo.app/public/images/shops/logo/101-1678635551.webp",
            "min_amount": 5, "status": "approved", "type": None, "status_note": "approved", "delivery_time": '{"from":"30.0","to":"60","type":"minute"}',
            "price": 0, "price_per_km": 0, "service_fee": 0, "verify": 1, "order_payment": "before", "new_order_after_payment": 0, "name": "BWI Studios"
        },
        {
            "id": 9001, "slug": "juvomart-9001", "uuid": "75d0c63d-600a-4cf8-a308-73b6cde467e4", "user_id": 149, "tax": 0.00, "percentage": 15,
            "location": '{"latitude":"-22.342385264868007","longitude":"30.016277228408626"}', "phone": "27790345401", "show_type": 1, "open": 1, "visibility": 0,
            "background_img": "https://s3.juvo.app/public/images/shops/background/101-1721855317.webp", "logo_img": "https://s3.juvo.app/public/images/shops/logo/101-1721855145.webp",
            "min_amount": 80, "status": "approved", "type": None, "status_note": "approved", "delivery_time": '{"from":"30","to":"60","type":"minute"}',
            "price": 0, "price_per_km": 0, "service_fee": 0, "verify": 1, "order_payment": "before", "new_order_after_payment": 0, "name": "JuvoMart"
        },
        {
            "id": 9003, "slug": "south-river-9003", "uuid": "69a373f8-573e-40bf-9ba3-8eb7ca217be5", "user_id": 147, "tax": 0.00, "percentage": 100,
            "location": '{"latitude":"-22.342385264868007","longitude":"30.016277228408626"}', "phone": "27790345401", "show_type": 1, "open": 1, "visibility": 0,
            "background_img": "https://s3.juvo.app/public/images/shops/background/101-1691405780.webp", "logo_img": "https://s3.juvo.app/public/images/shops/logo/101-1682413198.webp",
            "min_amount": 0, "status": "approved", "type": None, "status_note": "approved", "delivery_time": '{"from":"30","to":"60","type":"minute"}',
            "price": 0, "price_per_km": 0, "service_fee": 0, "verify": 1, "order_payment": "before", "new_order_after_payment": 0, "name": "South River"
        }
    ]

    # Branches data from branches.sql (no INSERT statements, so this is an assumption)
    branches_data = [
        {"shop_id": 504, "address": "KFC Musina CBD Address", "location": '{"latitude":"-22.3568125","longitude":"30.03256249999999"}', "name": "KFC Musina CBD - Main"},
        {"shop_id": 505, "address": "Nandos Address", "location": '{"latitude":"-22.340539864424997","longitude":"30.041396928838118"}', "name": "Nandos - Main"},
        {"shop_id": 9000, "address": "BWI Studios Address", "location": '{"latitude":"-22.3381123","longitude":"30.0122431"}', "name": "BWI Studios - Main"},
        {"shop_id": 9001, "address": "JuvoMart Address", "location": '{"latitude":"-22.342385264868007","longitude":"30.016277228408626"}', "name": "JuvoMart - Main"},
        {"shop_id": 9003, "address": "South River Address", "location": '{"latitude":"-22.342385264868007","longitude":"30.016277228408626"}', "name": "South River - Main"}
    ]

    print("--- Running Step: Seeding Shops ---")
    for shop_data in shops_data:
        try:
            if not frappe.db.exists("Shop", {"name": shop_data.get("name")} ):
                shop = frappe.new_doc("Shop")
                shop.shop_name = shop_data.get("name")
                shop.slug = shop_data.get("slug")
                shop.user = frappe.db.get_value("User", {"old_user_id": shop_data.get("user_id")}, "name") or "Administrator"
                shop.tax = shop_data.get("tax")
                shop.percentage = shop_data.get("percentage")
                shop.location = shop_data.get("location")
                shop.phone = shop_data.get("phone")
                shop.logo_img = shop_data.get("logo_img")
                shop.background_img = shop_data.get("background_img")
                shop.min_amount = shop_data.get("min_amount")
                shop.status = shop_data.get("status", "approved").capitalize()
                shop.delivery_time = shop_data.get("delivery_time")
                shop.service_fee = shop_data.get("service_fee")
                # Frappe uses 0 or 1 for checkboxes
                shop.verify = 1 if shop_data.get("verify") else 0
                shop.open = 1 if shop_data.get("open") else 0
                shop.visibility = 1 if shop_data.get("visibility") else 0

                # Set a placeholder name for the document to link it before it's saved
                shop.name = shop_data.get("name")
                shop.old_shop_id = shop_data.get("id")

                shop.insert(ignore_permissions=True)
                print(f"SUCCESS: Imported Shop '{shop.shop_name}'")
            else:
                # Update old_shop_id if shop exists, to link branches correctly
                frappe.db.set_value("Shop", shop_data.get("name"), "old_shop_id", shop_data.get("id"))
                print(f"SKIPPED: Shop '{shop_data.get('name')}' already exists.")
        except Exception as e:
            print(f"ERROR: Failed to import shop '{shop_data.get('name')}'. Reason: {e}")

    print("\n--- Running Step: Seeding Branches ---")
    for branch_data in branches_data:
        try:
            shop_name = frappe.db.get_value("Shop", {"old_shop_id": branch_data.get("shop_id")}, "name")
            if shop_name and not frappe.db.exists("Branch", {"name": branch_data.get("name")}):
                branch = frappe.new_doc("Branch")
                branch.branch_name = branch_data.get("name")
                branch.shop = shop_name
                branch.address = branch_data.get("address")
                branch.location = branch_data.get("location")
                branch.insert(ignore_permissions=True)
                print(f"SUCCESS: Imported Branch '{branch.branch_name}' for Shop '{shop_name}'")
            elif not shop_name:
                 print(f"SKIPPED: Branch '{branch_data.get('name')}' because parent Shop was not found.")
            else:
                print(f"SKIPPED: Branch '{branch_data.get('name')}' already exists.")
        except Exception as e:
            print(f"ERROR: Failed to import branch '{branch_data.get('name')}'. Reason: {e}")

    frappe.db.commit()
    print("\n--- Seeding of Shops and Branches complete ---")