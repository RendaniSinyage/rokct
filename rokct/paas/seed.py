# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import os
import re
import json
from frappe.utils import get_site_path, get_bench_path

class LegacyDataSeeder:
    def __init__(self, site_name, db_path):
        self.site_name = site_name
        self.db_path = db_path
        self.user_id_map = {}
        self.shop_id_map = {}
        self.brand_id_map = {}
        self.category_id_map = {}
        self.unit_id_map = {}
        self.product_id_map = {}
        self.stock_id_map = {}
        self.orders_map = {}
        self.addresses_to_insert = []
        self.user_address_map = {} # old_id -> new_name

    def _safe_split(self, values_str):
        # A simple way to handle commas inside quotes
        values = []
        in_quote = False
        current_val = ''
        i = 0
        while i < len(values_str):
            char = values_str[i]

            if char == "'":
                in_quote = not in_quote
                current_val += char
            elif char == ',' and not in_quote:
                values.append(current_val)
                current_val = ''
            else:
                current_val += char
            i += 1
        values.append(current_val)
        return [self._clean_value(v) for v in values]


    def _clean_value(self, value):
        if value is None:
            return None
        value = value.strip()
        if value == 'NULL':
            return None
        if value.startswith("'") and value.endswith("'"):
            return value[1:-1]
        return value

    def _map_user_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `users` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    name = self._clean_value(parts[1])
                    email = self._clean_value(parts[2])
                    phone = self._clean_value(parts[4])

                    if not email or frappe.db.exists("User", email):
                        email = f"user_{old_id}@example.com"
                        if frappe.db.exists("User", email):
                           self.user_id_map[old_id] = email
                           continue

                    first_name = name.split(' ')[0] if name else f"User_{old_id}"
                    last_name = ' '.join(name.split(' ')[1:]) if name and ' ' in name else 'User'

                    user_doc = {
                        "doctype": "User",
                        "email": email,
                        "first_name": first_name,
                        "last_name": last_name,
                        "phone": phone,
                        "send_welcome_email": 0,
                        "roles": [{"role": "Customer"}]
                    }
                    self.user_id_map[old_id] = email
                    frappe.get_doc(user_doc).insert(ignore_permissions=True)
                    print(f"Inserted User: {email}")

                except Exception as e:
                    print(f"Error inserting user: {values_str} -> {e}")

    def _map_shop_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `shops` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    name = self._clean_value(parts[10])

                    if not name:
                        continue

                    company_name = f"{name} - {old_id}"
                    if frappe.db.exists("Company", company_name):
                        self.shop_id_map[old_id] = company_name
                        continue

                    company_doc = {
                        "doctype": "Company",
                        "company_name": company_name,
                        "country": "South Africa",
                        "default_currency": "ZAR"
                    }
                    doc = frappe.get_doc(company_doc)
                    doc.insert(ignore_permissions=True)
                    self.shop_id_map[old_id] = doc.name
                    print(f"Inserted Company: {doc.name}")

                except Exception as e:
                    print(f"Error inserting company: {values_str} -> {e}")

    def _map_brand_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `brands` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    title = self._clean_value(parts[2])

                    if not title:
                        continue

                    if frappe.db.exists("Brand", title):
                        self.brand_id_map[old_id] = title
                        continue

                    brand_doc = {"doctype": "Brand", "brand": title}
                    doc = frappe.get_doc(brand_doc)
                    doc.insert(ignore_permissions=True)
                    self.brand_id_map[old_id] = doc.name
                    print(f"Inserted Brand: {doc.name}")
                except Exception as e:
                    print(f"Error inserting brand: {values_str} -> {e}")

    def _map_category_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `categories` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    title = self._clean_value(parts[2])
                    parent_id = parts[4]

                    if not title:
                        continue

                    item_group_name = title
                    if frappe.db.exists("Item Group", item_group_name):
                        self.category_id_map[old_id] = item_group_name
                        continue

                    item_group_doc = {
                        "doctype": "Item Group",
                        "item_group_name": item_group_name,
                        "is_group": 1
                    }

                    if parent_id and parent_id in self.category_id_map:
                        item_group_doc["parent_item_group"] = self.category_id_map[parent_id]
                    else:
                        item_group_doc["parent_item_group"] = "All Item Groups"

                    doc = frappe.get_doc(item_group_doc)
                    doc.insert(ignore_permissions=True)
                    self.category_id_map[old_id] = doc.name
                    print(f"Inserted Item Group: {doc.name}")
                except Exception as e:
                    print(f"Error inserting item group: {values_str} -> {e}")

    def _map_unit_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `units` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    name = self._clean_value(parts[2])

                    if not name or frappe.db.exists("UOM", name):
                        self.unit_id_map[old_id] = name
                        continue

                    uom_doc = {"doctype": "UOM", "uom_name": name}
                    doc = frappe.get_doc(uom_doc)
                    doc.insert(ignore_permissions=True)
                    self.unit_id_map[old_id] = doc.name
                    print(f"Inserted UOM: {doc.name}")
                except Exception as e:
                    print(f"Error inserting UOM: {values_str} -> {e}")

    def _map_product_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `products` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)

                    old_id = parts[0]
                    title = self._clean_value(parts[2])
                    category_id = parts[4]
                    brand_id = parts[6]

                    item_code = f"{title}-{old_id}"
                    if frappe.db.exists("Item", item_code):
                        self.product_id_map[old_id] = item_code
                        continue

                    item_group = self.category_id_map.get(category_id, "All Item Groups")
                    brand = self.brand_id_map.get(brand_id)

                    item_doc = {
                        "doctype": "Item",
                        "item_code": item_code,
                        "item_name": title,
                        "item_group": item_group,
                        "brand": brand,
                        "stock_uom": "Nos",
                        "is_stock_item": 1
                    }

                    doc = frappe.get_doc(item_doc)
                    doc.insert(ignore_permissions=True)
                    self.product_id_map[old_id] = item_code
                    print(f"Inserted Item: {doc.name}")

                except Exception as e:
                    print(f"Error inserting item: {values_str} -> {e}")

    def _map_stock_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `stocks` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    stock_id = parts[0]
                    product_id = parts[1]

                    item_code = self.product_id_map.get(product_id)
                    if item_code:
                        self.stock_id_map[stock_id] = item_code

                except Exception as e:
                    print(f"Error mapping stock: {values_str} -> {e}")

    def _map_user_address_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `user_addresses` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    title = self._clean_value(parts[1])
                    user_id = parts[2]
                    address_json_str = parts[3]

                    customer_email = self.user_id_map.get(user_id)
                    customer_name = frappe.db.get_value("Customer", {"email_id": customer_email}, "name") if customer_email else None
                    if not customer_name:
                        continue

                    address_line1 = "N/A"
                    try:
                        address_data = json.loads(address_json_str)
                        address_line1 = address_data.get('address') or "N/A"
                    except (json.JSONDecodeError, IndexError):
                        pass

                    address_doc = {
                        "doctype": "Address",
                        "address_title": title or customer_name,
                        "address_type": "Shipping",
                        "address_line1": address_line1,
                        "city": "Musina",
                        "country": "South Africa",
                        "is_primary_address": 1,
                        "links": [{"link_doctype": "Customer", "link_name": customer_name}]
                    }
                    self.addresses_to_insert.append((old_id, address_doc))
                except Exception as e:
                    print(f"Error parsing user_address line: {values_str} -> {e}")

    def _insert_addresses(self):
        for old_id, address_doc in self.addresses_to_insert:
            try:
                existing_address = frappe.db.exists("Address", {
                    "address_title": address_doc["address_title"],
                    "address_line1": address_doc["address_line1"],
                    "links.link_name": address_doc["links"][0]["link_name"]
                })
                if not existing_address:
                    doc = frappe.get_doc(address_doc)
                    doc.insert(ignore_permissions=True)
                    self.user_address_map[old_id] = doc.name
                    print(f"Inserted Address: {doc.name}")
                else:
                    self.user_address_map[old_id] = existing_address
            except Exception as e:
                print(f"Error inserting address: {address_doc['address_title']} -> {e}")

    def _map_order_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `orders` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    old_id = parts[0]
                    user_id = parts[1]
                    shop_id = parts[6]
                    status = self._clean_value(parts[9])
                    delivery_type = self._clean_value(parts[17])
                    created_at = self._clean_value(parts[19])
                    address_id = self._clean_value(parts[22])

                    customer_email = self.user_id_map.get(user_id)
                    customer_name = frappe.db.get_value("Customer", {"email_id": customer_email}, "name") if customer_email else None
                    company_name = self.shop_id_map.get(shop_id)

                    if not customer_name or not company_name:
                        continue

                    workflow_state = "Draft"
                    if status == 'delivered':
                        workflow_state = "Completed"
                    elif status == 'canceled':
                        workflow_state = "Cancelled"

                    shipping_address_name = self.user_address_map.get(address_id)

                    order_doc = {
                        "doctype": "Sales Order",
                        "naming_series": "SO-",
                        "customer": customer_name,
                        "company": company_name,
                        "order_type": "Sales",
                        "transaction_date": created_at.split(' ')[0] if created_at else None,
                        "workflow_state": workflow_state,
                        "docstatus": 0,
                        "items": [],
                        "set_warehouse": "Stores - J",
                        "shipping_address_name": shipping_address_name,
                        "custom_delivery_type": delivery_type,
                        "custom_legacy_order_id": old_id,
                    }
                    self.orders_map[old_id] = order_doc
                except Exception as e:
                    print(f"Error parsing order line: {values_str} -> {e}")

    def _map_order_details_data(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        insert_statements = re.findall(r"INSERT INTO `order_details` VALUES \((.*?)\);", content)
        for statement in insert_statements:
            values_list = re.findall(r"\((.*?)\)", statement)
            for values_str in values_list:
                try:
                    parts = self._safe_split(values_str)
                    order_id = parts[1]
                    stock_id = parts[2]
                    price = float(parts[3])
                    quantity = int(parts[7])

                    if order_id not in self.orders_map:
                        continue

                    item_code = self.stock_id_map.get(stock_id)
                    if not item_code:
                        continue

                    item_doc = {
                        "item_code": item_code,
                        "qty": quantity,
                        "rate": price,
                    }
                    self.orders_map[order_id]["items"].append(item_doc)
                except Exception as e:
                    print(f"Error parsing order_details line: {values_str} -> {e}")

    def _insert_orders(self):
        for old_id, order_data in self.orders_map.items():
            try:
                if not frappe.db.exists("Sales Order", {"custom_legacy_order_id": old_id}):
                    doc = frappe.get_doc(order_data)
                    doc.insert(ignore_permissions=True)
                    if doc.workflow_state in ["Completed", "Cancelled"]:
                        doc.submit()
                    print(f"Inserted Sales Order: {doc.name}")
            except Exception as e:
                print(f"Error inserting Sales Order {old_id}: {e}")
                frappe.log_error(frappe.get_traceback(), f"Seeder Error: Sales Order {old_id}")


    def run(self):
        # The site is already connected by the `bench execute` command.
        # We just need to ensure we're running as Administrator.
        frappe.local.user = frappe.get_doc("User", "Administrator")

        # Phase 1: Users and Companies (Shops)
        print("--- Starting Phase 1: Users and Companies ---")
        self._map_user_data(os.path.join(self.db_path, 'users.sql'))
        self._map_shop_data(os.path.join(self.db_path, 'shops.sql'))

        # Create Customers from Users
        for user_email in self.user_id_map.values():
            if user_email and not frappe.db.exists("Customer", {"email_id": user_email}):
                user_doc = frappe.get_doc("User", user_email)
                customer = frappe.new_doc("Customer")
                customer.customer_name = user_doc.get_fullname()
                customer.customer_type = "Individual"
                customer.email_id = user_email
                customer.mobile_no = user_doc.phone
                customer.insert(ignore_permissions=True)
                print(f"Created Customer for {user_email}")

        frappe.db.commit()

        # Phase 2: Item related meta
        print("\n--- Starting Phase 2: Item Metadata ---")
        self._map_brand_data(os.path.join(self.db_path, 'brands.sql'))
        self._map_category_data(os.path.join(self.db_path, 'categories.sql'))
        self._map_unit_data(os.path.join(self.db_path, 'units.sql'))
        frappe.db.commit()

        # Phase 3: Items and Stocks
        print("\n--- Starting Phase 3: Items and Stocks ---")
        self._map_product_data(os.path.join(self.db_path, 'products.sql'))
        self._map_stock_data(os.path.join(self.db_path, 'stocks.sql'))
        frappe.db.commit()

        # Phase 4: User Addresses
        print("\n--- Starting Phase 4: User Addresses ---")
        self._map_user_address_data(os.path.join(self.db_path, 'user_addresses.sql'))
        self._insert_addresses()
        frappe.db.commit()

        # Phase 5: Orders and Order Details
        print("\n--- Starting Phase 5: Orders and Order Details ---")
        self._map_order_data(os.path.join(self.db_path, 'orders.sql'))
        self._map_order_details_data(os.path.join(self.db_path, 'order_details.sql'))
        self._insert_orders()
        frappe.db.commit()

def run_seeder():
    # This seeder is intended to run only on a specific site.
    target_site_name = "juvo.tenant.rokct.ai"
    current_site = frappe.local.site

    if current_site != target_site_name:
        print(f"Skipping data import for site '{current_site}'. This seeder is intended for '{target_site_name}' only.")
        return

    print(f"--- Starting data import for site '{current_site}' ---")

    bench_path = get_bench_path()
    db_path = os.path.join(bench_path, "apps/rokct/rokct/paas/db")

    seeder = LegacyDataSeeder(site_name=current_site, db_path=db_path)
    seeder.run()

if __name__ == "__main__":
    run_seeder()