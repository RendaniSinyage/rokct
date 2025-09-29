import frappe
from frappe.model.document import Document

def execute():
    if frappe.local.site != 'juvo.tenant.rokct.ai':
        return

    # User mapping: user_id -> (first_name, last_name)
    users_data = {
        1: ("South", "River"),
        101: ("Juvo", "Admin"),
        241: ("default", "customer")
    }

    # Shop mapping: shop_id -> shop_name
    shops_data = {
        101: "MiBand",
        102: "Burger"
    }

    # Order data from orders.sql
    orders_data = [
        {'id': 1, 'user_id': 1, 'total': 15.00, 'shop_id': 101, 'status': 'new', 'created_at': '2022-07-13 00:03:00', 'updated_at': '2022-07-13 00:03:00'},
        {'id': 2, 'user_id': 1, 'total': 30.00, 'shop_id': 101, 'status': 'new', 'created_at': '2022-07-13 00:03:18', 'updated_at': '2022-07-13 00:03:18'},
        {'id': 3, 'user_id': 1, 'total': 120.00, 'shop_id': 102, 'status': 'new', 'created_at': '2022-07-13 23:25:35', 'updated_at': '2022-07-13 23:25:35'},
        {'id': 4, 'user_id': 1, 'total': 120.00, 'shop_id': 101, 'status': 'new', 'created_at': '2022-07-14 23:25:35', 'updated_at': '2022-07-14 23:25:35'},
        {'id': 5, 'user_id': 101, 'total': 25.00, 'shop_id': 101, 'status': 'new', 'created_at': '2023-01-23 15:55:00', 'updated_at': '2023-01-23 15:55:00'},
        {'id': 6, 'user_id': 101, 'total': 10.00, 'shop_id': 101, 'status': 'new', 'created_at': '2023-01-23 15:55:12', 'updated_at': '2023-01-23 15:55:12'},
        {'id': 7, 'user_id': 101, 'total': 10.00, 'shop_id': 101, 'status': 'new', 'created_at': '2023-01-24 11:37:25', 'updated_at': '2023-01-24 11:37:25'},
        {'id': 8, 'user_id': 241, 'total': 10.00, 'shop_id': 101, 'status': 'new', 'created_at': '2024-04-30 00:00:00', 'updated_at': '2024-04-30 00:00:00'},
        {'id': 9, 'user_id': 241, 'total': 10.00, 'shop_id': 101, 'status': 'new', 'created_at': '2024-05-01 00:00:00', 'updated_at': '2024-05-01 00:00:00'},
        {'id': 10, 'user_id': 241, 'total': 10.00, 'shop_id': 101, 'status': 'new', 'created_at': '2024-05-22 00:00:00', 'updated_at': '2024-05-22 00:00:00'}
    ]

    # Order items data from order_details.sql
    order_items_data = {
        1: [{'product_id': 1, 'price': 15.00, 'quantity': 1}],
        2: [{'product_id': 1, 'price': 15.00, 'quantity': 2}],
        3: [{'product_id': 2, 'price': 120.00, 'quantity': 1}],
        4: [{'product_id': 1, 'price': 120.00, 'quantity': 1}],
        5: [{'product_id': 1, 'price': 10.00, 'quantity': 1}, {'product_id': 2, 'price': 15.00, 'quantity': 1}],
        6: [{'product_id': 1, 'price': 10.00, 'quantity': 1}],
        7: [{'product_id': 1, 'price': 10.00, 'quantity': 1}],
        8: [{'product_id': 1, 'price': 10.00, 'quantity': 1}],
        9: [{'product_id': 1, 'price': 10.00, 'quantity': 1}],
        10: [{'product_id': 1, 'price': 10.00, 'quantity': 1}]
    }

    for order_data in orders_data:
        order_id = order_data['id']
        if frappe.db.exists("Order", {"name": f"ORD-{order_id}"}):
            continue

        user_id = order_data['user_id']
        shop_id = order_data['shop_id']

        customer_name = " ".join(users_data.get(user_id, ("Unknown", "User")))
        customer = frappe.get_value("Customer", {"customer_name": customer_name}, "name")
        if not customer:
            customer_doc = frappe.get_doc({
                "doctype": "Customer",
                "customer_name": customer_name,
                "customer_type": "Individual"
            })
            customer_doc.insert(ignore_permissions=True)
            customer = customer_doc.name

        shop_name = shops_data.get(shop_id)
        if not shop_name:
            continue

        order = frappe.get_doc({
            "doctype": "Order",
            "name": f"ORD-{order_id}",
            "customer": customer,
            "shop": shop_name,
            "status": order_data['status'].capitalize(),
            "creation": order_data['created_at'],
            "modified": order_data['updated_at'],
            "grand_total": order_data['total'],
            "items": []
        })

        if order_id in order_items_data:
            for item_data in order_items_data[order_id]:
                # Assuming product_id from legacy maps to an Item's name or code
                # This part might need adjustment based on how products are seeded
                item_code = f"Test Product {item_data['product_id']}"
                if not frappe.db.exists("Item", item_code):
                    frappe.get_doc({"doctype": "Item", "item_code": item_code, "item_name": item_code, "item_group": "Products"}).insert(ignore_permissions=True)

                order.append("items", {
                    "item_code": item_code,
                    "qty": item_data['quantity'],
                    "rate": item_data['price']
                })

        order.insert(ignore_permissions=True)
    frappe.db.commit()