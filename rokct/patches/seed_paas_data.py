# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import os
import re
import json

# --- Global ID Mappings for legacy data ---
user_id_to_name_map = {}
shop_id_to_company_name_map = {}
category_id_to_name_map = {}
brand_id_to_name_map = {}
unit_id_to_name_map = {}
kitchen_id_to_name_map = {}
product_id_to_name_map = {}

def execute():
    """
    Seeds a vast amount of legacy data from the `paas/db` directory
    for the `juvo.tenant.rokct.ai` site ONLY.
    """
    if frappe.local.site != "juvo.tenant.rokct.ai":
        print("--- SKIPPING PAAS LEGACY DATA SEEDER: Not running on juvo.tenant.rokct.ai ---")
        return

    print("\n--- Starting PAAS Legacy Data Seeder for juvo.tenant.rokct.ai ---")

    _preload_category_names()

    # --- Phase 1: Core Foundational Data ---
    phase1_files = [
        ("users.sql", "User", _map_user_data),
        ("shops.sql", "Company", _map_shop_data),
        ("brands.sql", "Brand", _map_brand_data),
        ("units.sql", "UOM", _map_unit_data),
        ("kitchens.sql", "Kitchen", _map_kitchen_data),
        ("categories.sql", "Item Group", _map_category_data),
    ]
    print("\n\n--- EXECUTING PHASE 1: CORE FOUNDATIONAL DATA ---")
    for sql_file, doctype, mapping_func in phase1_files:
        _process_sql_file(sql_file, doctype, mapping_func)

    # --- Phase 2: Product Data ---
    phase2_files = [
        ("products.sql", "Item", _map_product_data),
    ]
    print("\n\n--- EXECUTING PHASE 2: PRODUCT DATA ---")
    for sql_file, doctype, mapping_func in phase2_files:
        _process_sql_file(sql_file, doctype, mapping_func)

    print("\n--- PAAS Legacy Data Seeder Finished ---")


def _process_sql_file(filename, doctype, mapping_function):
    """Generic function to process a single SQL file."""
    print(f"\n--- Processing: {filename} ---")

    app_path = frappe.get_app_path("rokct")
    file_path = os.path.join(app_path, "paas", "db", filename)

    if not os.path.exists(file_path):
        print(f"ERROR: File not found at {file_path}. Skipping.")
        return

    with open(file_path, 'r') as f:
        content = f.read()

    insert_regex = re.compile(r"INSERT INTO `.*?` VALUES (\(.*?\));", re.DOTALL)

    for match in insert_regex.finditer(content):
        try:
            import ast
            values_tuple = ast.literal_eval(match.group(1))
            values = [str(v).strip() if v is not None else None for v in values_tuple]
        except (ValueError, SyntaxError):
            print(f"WARNING: Could not parse values tuple: {match.group(1)}. Skipping record.")
            continue

        try:
            doc_data = mapping_function(values)
            if not doc_data: continue

            doc_name = doc_data.get("name") or doc_data.get("item_code")
            if not doc_name:
                print(f"SKIPPED: No name or identifier found for record. Values: {values}")
                continue

            if frappe.db.exists(doctype, doc_name):
                print(f"SKIPPED: {doctype} '{doc_name}' already exists.")
                continue

            doc = frappe.new_doc(doctype)
            doc.update(doc_data)

            if doctype == "User" and 'new_password' in doc_data:
                doc.set("new_password", doc_data['new_password'])

            doc.insert(ignore_permissions=True)
            print(f"SUCCESS: Created {doctype} '{doc.name}'.")

        except Exception as e:
            print(f"ERROR: Failed to process a record from {filename}. Reason: {e}")
            frappe.log_error(f"Failed to process record from {filename}", f"Values: {values}\nError: {frappe.get_traceback()}")

    frappe.db.commit()

# --- Mapping Functions ---

def _map_user_data(values):
    if len(values) < 5: return None
    old_user_id, email = values[0], values[4]
    if not email or email == 'NULL': return None
    user_id_to_name_map[old_user_id] = email
    return { "doctype": "User", "email": email, "first_name": values[2] or email.split('@')[0], "last_name": values[3] or "User", "enabled": 1, "send_welcome_email": 0, "new_password": "temp_password_for_migration_123" }

def _map_shop_data(values):
    if len(values) < 4: return None
    old_shop_id, slug = values[0], values[1]
    company_name = slug.replace('-', ' ').replace('_', ' ').title() if slug and slug != 'NULL' else f"Shop-{old_shop_id}"
    shop_id_to_company_name_map[old_shop_id] = company_name
    return { "doctype": "Company", "name": company_name, "company_name": company_name, "default_currency": "USD", "country": "South Africa" }

def _map_kitchen_data(values):
    if len(values) < 2: return None
    old_kitchen_id, old_shop_id = values[0], values[1]
    company_name = shop_id_to_company_name_map.get(old_shop_id)
    if not company_name: return None
    kitchen_name = f"{company_name} Kitchen"
    kitchen_id_to_name_map[old_kitchen_id] = kitchen_name
    return { "doctype": "Kitchen", "name": kitchen_name, "shop": company_name, "active": int(values[2] or 0) }

def _map_brand_data(values):
    if len(values) < 4: return None
    old_brand_id, brand_name = values[0], values[3]
    if not brand_name or brand_name == 'NULL': return None
    brand_id_to_name_map[old_brand_id] = brand_name
    return { "doctype": "Brand", "name": brand_name, "brand_name": brand_name, "description": brand_name }

def _map_unit_data(values):
    if len(values) < 2: return None
    old_unit_id, unit_name = values[0], values[1]
    if not unit_name or unit_name == 'NULL': return None
    unit_id_to_name_map[old_unit_id] = unit_name
    return { "doctype": "UOM", "uom_name": unit_name }

def _preload_category_names():
    print("\n--- Pre-loading Category Names ---")
    app_path = frappe.get_app_path("rokct")
    file_path = os.path.join(app_path, "paas", "db", "category_translations.sql")
    if not os.path.exists(file_path): return

    with open(file_path, 'r') as f: content = f.read()
    insert_regex = re.compile(r"INSERT INTO `.*?` VALUES (\(.*?\));", re.DOTALL)
    for match in insert_regex.finditer(content):
        try:
            import ast
            values_tuple = ast.literal_eval(match.group(1))
            if len(values_tuple) >= 4:
                cat_id, locale, title = str(values_tuple[1]), values_tuple[2], values_tuple[3]
                if locale == 'en': category_id_to_name_map[cat_id] = title
        except (ValueError, SyntaxError): continue
    print(f"SUCCESS: Pre-loaded {len(category_id_to_name_map)} category names.")

def _map_category_data(values):
    if len(values) < 5: return None
    old_cat_id, parent_id = values[0], values[4]
    item_group_name = category_id_to_name_map.get(old_cat_id)
    if not item_group_name: return None

    parent_item_group = "All Item Groups"
    if parent_id and parent_id != '0':
        parent_name = category_id_to_name_map.get(parent_id)
        if parent_name: parent_item_group = parent_name

    return { "doctype": "Item Group", "name": item_group_name, "item_group_name": item_group_name, "parent_item_group": parent_item_group, "is_group": 1 }

def _map_product_data(values):
    """Maps values from `products.sql` to an Item DocType dictionary."""
    if len(values) < 4: return None

    old_product_id, slug, old_shop_id, old_category_id, old_brand_id, old_unit_id = values[0], values[1], values[3], values[4], values[5], values[6]

    item_code = slug if slug and slug != 'NULL' else f"product-{old_product_id}"

    company = shop_id_to_company_name_map.get(old_shop_id)
    item_group = category_id_to_name_map.get(old_category_id)
    brand = brand_id_to_name_map.get(old_brand_id)
    stock_uom = unit_id_to_name_map.get(old_unit_id)

    if not company or not item_group:
        print(f"WARNING: Missing Company or Item Group for product ID {old_product_id}. Skipping.")
        return None

    product_id_to_name_map[old_product_id] = item_code

    return {
        "doctype": "Item",
        "item_code": item_code,
        "item_name": item_code.replace('-', ' ').title(),
        "item_group": item_group,
        "brand": brand,
        "stock_uom": stock_uom,
        "is_stock_item": 0, # Assuming all are service items for now
        "company": company
    }