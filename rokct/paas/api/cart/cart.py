import frappe

@frappe.whitelist()
def get_cart(shop_id: str):
    """
    Retrieves the active cart for the current user and a given shop.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your cart.")

    # Find the main Cart document
    cart_name = frappe.db.get_value("Cart", {"owner": user, "shop": shop_id, "status": "Active"}, "name")
    if not cart_name:
        return None # No active cart

    # Find the User Cart document
    user_cart = frappe.get_doc("User Cart", {"user": user, "cart": cart_name})

    return user_cart.as_dict()


@frappe.whitelist()
def add_to_cart(item_code: str, qty: int, shop_id: str):
    """
    Adds an item to the user's cart for a specific shop.
    Creates the cart if it doesn't exist.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to add items to your cart.")

    if not frappe.db.exists("Item", item_code):
        frappe.throw("Item not found.")

    item = frappe.get_doc("Item", item_code)
    price = item.standard_rate

    # Find or create the main Cart document
    cart_name = frappe.db.get_value("Cart", {"owner": user, "shop": shop_id, "status": "Active"}, "name")
    if not cart_name:
        cart = frappe.get_doc({
            "doctype": "Cart",
            "owner": user,
            "shop": shop_id,
            "status": "Active"
        }).insert(ignore_permissions=True)
        cart_name = cart.name

    # Find or create the User Cart document
    user_cart_name = frappe.db.get_value("User Cart", {"user": user, "cart": cart_name}, "name")
    if not user_cart_name:
        user_cart = frappe.get_doc({
            "doctype": "User Cart",
            "user": user,
            "cart": cart_name
        }).insert(ignore_permissions=True)
    else:
        user_cart = frappe.get_doc("User Cart", user_cart_name)

    # Check if item already exists in cart
    existing_item = None
    for detail in user_cart.cart_details:
        if detail.item == item_code:
            existing_item = detail
            break

    if existing_item:
        existing_item.quantity += qty
    else:
        user_cart.append("cart_details", {
            "item": item_code,
            "quantity": qty,
            "price": price,
        })

    user_cart.save(ignore_permissions=True)

    # Recalculate totals
    calculate_cart_totals(cart_name)

    return user_cart.as_dict()


@frappe.whitelist()
def remove_from_cart(cart_detail_name: str):
    """
    Removes an item from the cart.
    `cart_detail_name` is the name of the Cart Detail row.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to modify your cart.")

    # This is not fully secure, as a user could guess a cart_detail_name.
    # A proper implementation would check ownership of the parent User Cart.
    # For this migration, we assume the frontend provides the correct ID.

    cart_detail = frappe.get_doc("Cart Detail", cart_detail_name)
    user_cart = frappe.get_doc("User Cart", cart_detail.parent)

    if user_cart.user != user:
        frappe.throw("You are not authorized to remove this item.", frappe.PermissionError)

    cart_name = user_cart.cart

    # Remove the item
    user_cart.remove(cart_detail)
    user_cart.save(ignore_permissions=True)

    # Recalculate totals
    calculate_cart_totals(cart_name)
    return {"status": "success", "message": "Item removed from cart."}


def calculate_cart_totals(cart_name: str):
    """
    Helper function to recalculate the total price of a cart.
    """
    cart = frappe.get_doc("Cart", cart_name)
    total_price = 0

    user_carts = frappe.get_all("User Cart", filters={"cart": cart_name}, fields=["name"])
    for uc in user_carts:
        user_cart = frappe.get_doc("User Cart", uc.name)
        for detail in user_cart.cart_details:
            total_price += detail.price * detail.quantity

    cart.total_price = total_price
    cart.save(ignore_permissions=True)