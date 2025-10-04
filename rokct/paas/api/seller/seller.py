import frappe
import json
import uuid
from rokct.rokct.tenant.api import get_subscription_details

def _get_seller_shop(user_id):
    """Helper function to get the shop for a given user."""
    if not user_id or user_id == "Guest":
        frappe.throw("You must be logged in to perform this action.", frappe.AuthenticationError)

    # Assuming 'user_id' is a custom field on the Company doctype linking to the User
    shop = frappe.db.get_value("Company", {"user_id": user_id}, "name")
    if not shop:
        frappe.throw("User is not linked to any shop.", frappe.PermissionError)

    return shop


@frappe.whitelist()
def get_seller_statistics():
    """
    Retrieves sales and order statistics for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    total_sales = frappe.db.sql("""
        SELECT SUM(grand_total)
        FROM `tabOrder`
        WHERE shop = %(shop)s AND status = 'Delivered'
    """, {"shop": shop})[0][0] or 0

    total_orders = frappe.db.count("Order", {"shop": shop})

    top_selling_products = frappe.db.sql("""
        SELECT oi.product, i.item_name, SUM(oi.quantity) as total_quantity
        FROM `tabOrder Item` as oi
        JOIN `tabOrder` as o ON o.name = oi.parent
        JOIN `tabItem` as i ON i.name = oi.product
        WHERE o.shop = %(shop)s
        GROUP BY oi.product, i.item_name
        ORDER BY total_quantity DESC
        LIMIT 10
    """, {"shop": shop}, as_dict=True)

    return {
        "total_sales": total_sales,
        "total_orders": total_orders,
        "top_selling_products": top_selling_products
    }


@frappe.whitelist()
def get_seller_sales_report(from_date: str, to_date: str):
    """
    Retrieves a sales report for the current seller's shop within a date range.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    sales_report = frappe.get_all(
        "Order",
        filters={
            "shop": shop,
            "creation": ["between", [from_date, to_date]]
        },
        fields=["name", "user", "grand_total", "status", "creation"],
        order_by="creation desc"
    )
    return sales_report


@frappe.whitelist()
def get_seller_products(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of products for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    products = frappe.get_list(
        "Item",
        filters={"shop": shop},
        fields=["name", "item_name", "description", "image", "standard_rate"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return products


@frappe.whitelist()
def create_seller_product(product_data):
    """
    Creates a new product for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(product_data, str):
        product_data = json.loads(product_data)

    product_data["shop"] = shop
    # You might want to add more validation here

    new_product = frappe.get_doc({
        "doctype": "Item",
        **product_data
    })
    new_product.insert(ignore_permissions=True)
    return new_product.as_dict()


@frappe.whitelist()
def update_seller_product(product_name, product_data):
    """
    Updates a product for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(product_data, str):
        product_data = json.loads(product_data)

    product = frappe.get_doc("Item", product_name)

    if product.shop != shop:
        frappe.throw("You are not authorized to update this product.", frappe.PermissionError)

    product.update(product_data)
    product.save(ignore_permissions=True)
    return product.as_dict()


@frappe.whitelist()
def delete_seller_product(product_name):
    """
    Deletes a product for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    product = frappe.get_doc("Item", product_name)

    if product.shop != shop:
        frappe.throw("You are not authorized to delete this product.", frappe.PermissionError)

    frappe.delete_doc("Item", product_name, ignore_permissions=True)
    return {"status": "success", "message": "Product deleted successfully."}


@frappe.whitelist()
def get_seller_categories(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of categories for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    categories = frappe.get_list(
        "Category",
        filters={"shop": shop},
        fields=["name", "uuid", "type", "image", "active", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name desc"
    )
    return categories


@frappe.whitelist()
def create_seller_category(category_data):
    """
    Creates a new category for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(category_data, str):
        category_data = json.loads(category_data)

    category_data["shop"] = shop

    # Re-using the existing create_category function logic
    category_uuid = category_data.get("uuid") or str(uuid.uuid4())
    if not category_data.get("type"):
        frappe.throw("Category type is required.")
    if frappe.db.exists("Category", {"uuid": category_uuid}):
        frappe.throw("Category with this UUID already exists.")

    category = frappe.get_doc({
        "doctype": "Category",
        **category_data
    })
    category.insert(ignore_permissions=True)
    return category.as_dict()


@frappe.whitelist()
def update_seller_category(uuid, category_data):
    """
    Updates a category for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    category_name = frappe.db.get_value("Category", {"uuid": uuid}, "name")
    if not category_name:
        frappe.throw("Category not found.")

    category = frappe.get_doc("Category", category_name)
    if category.shop != shop:
        frappe.throw("You are not authorized to update this category.", frappe.PermissionError)

    if isinstance(category_data, str):
        category_data = json.loads(category_data)

    updatable_fields = ["slug", "keywords", "parent_category", "type", "image", "active", "status", "input"]
    for key, value in category_data.items():
        if key in updatable_fields:
            category.set(key, value)

    category.save(ignore_permissions=True)
    return category.as_dict()


@frappe.whitelist()
def delete_seller_category(uuid):
    """
    Deletes a category for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    category_name = frappe.db.get_value("Category", {"uuid": uuid}, "name")
    if not category_name:
        frappe.throw("Category not found.")

    category = frappe.get_doc("Category", category_name)
    if category.shop != shop:
        frappe.throw("You are not authorized to delete this category.", frappe.PermissionError)

    frappe.delete_doc("Category", category_name, ignore_permissions=True)
    return {"status": "success", "message": "Category deleted successfully."}


@frappe.whitelist()
def get_seller_brands(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of brands for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    brands = frappe.get_list(
        "Brand",
        filters={"shop": shop},
        fields=["name", "uuid", "title", "slug", "active", "image"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name desc"
    )
    return brands


@frappe.whitelist()
def create_seller_brand(brand_data):
    """
    Creates a new brand for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(brand_data, str):
        brand_data = json.loads(brand_data)

    brand_data["shop"] = shop

    # Re-using the existing create_brand function logic
    brand_uuid = brand_data.get("uuid") or str(uuid.uuid4())
    if not brand_data.get("title"):
        frappe.throw("Brand title is required.")
    if frappe.db.exists("Brand", {"uuid": brand_uuid}):
        frappe.throw("Brand with this UUID already exists.")

    brand = frappe.get_doc({
        "doctype": "Brand",
        **brand_data
    })
    brand.insert(ignore_permissions=True)
    return brand.as_dict()


@frappe.whitelist()
def update_seller_brand(uuid, brand_data):
    """
    Updates a brand for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    brand_name = frappe.db.get_value("Brand", {"uuid": uuid}, "name")
    if not brand_name:
        frappe.throw("Brand not found.")

    brand = frappe.get_doc("Brand", brand_name)
    if brand.shop != shop:
        frappe.throw("You are not authorized to update this brand.", frappe.PermissionError)

    if isinstance(brand_data, str):
        brand_data = json.loads(brand_data)

    updatable_fields = ["title", "slug", "active", "image"]
    for key, value in brand_data.items():
        if key in updatable_fields:
            brand.set(key, value)

    brand.save(ignore_permissions=True)
    return brand.as_dict()


@frappe.whitelist()
def delete_seller_brand(uuid):
    """
    Deletes a brand for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    brand_name = frappe.db.get_value("Brand", {"uuid": uuid}, "name")
    if not brand_name:
        frappe.throw("Brand not found.")

    brand = frappe.get_doc("Brand", brand_name)
    if brand.shop != shop:
        frappe.throw("You are not authorized to delete this brand.", frappe.PermissionError)

    frappe.delete_doc("Brand", brand_name, ignore_permissions=True)
    return {"status": "success", "message": "Brand deleted successfully."}


@frappe.whitelist()
def get_seller_orders(limit_start: int = 0, limit_page_length: int = 20, status: str = None, from_date: str = None, to_date: str = None):
    """
    Retrieves a list of orders for the current seller's shop, with optional filters.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    filters = {"shop": shop}
    if status:
        filters["status"] = status
    if from_date and to_date:
        filters["creation"] = ["between", [from_date, to_date]]

    orders = frappe.get_list(
        "Order",
        filters=filters,
        fields=["name", "user", "grand_total", "status", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_seller_shop_working_days():
    """
    Retrieves the working days for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    working_days = frappe.get_all(
        "Shop Working Day",
        filters={"shop": shop},
        fields=["day_of_week", "opening_time", "closing_time", "is_closed"]
    )
    return working_days


@frappe.whitelist()
def update_seller_shop_working_days(working_days_data):
    """
    Updates the working days for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(working_days_data, str):
        working_days_data = json.loads(working_days_data)

    # Clear existing working days for the shop
    frappe.db.delete("Shop Working Day", {"shop": shop})

    for day_data in working_days_data:
        frappe.get_doc({
            "doctype": "Shop Working Day",
            "shop": shop,
            **day_data
        }).insert(ignore_permissions=True)

    return {"status": "success", "message": "Working days updated successfully."}


@frappe.whitelist()
def get_seller_shop_closed_days():
    """
    Retrieves the closed days for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    closed_days = frappe.get_all(
        "Shop Closed Day",
        filters={"shop": shop},
        fields=["date"]
    )
    return [d.date for d in closed_days]


@frappe.whitelist()
def add_seller_shop_closed_day(date):
    """
    Adds a closed day for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    frappe.get_doc({
        "doctype": "Shop Closed Day",
        "shop": shop,
        "date": date
    }).insert(ignore_permissions=True)

    return {"status": "success", "message": "Closed day added successfully."}


@frappe.whitelist()
def delete_seller_shop_closed_day(date):
    """
    Deletes a closed day for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    frappe.db.delete("Shop Closed Day", {"shop": shop, "date": date})

    return {"status": "success", "message": "Closed day deleted successfully."}


@frappe.whitelist()
def get_shop_users(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of users for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    shop_users = frappe.get_all(
        "User Shop",
        filters={"shop": shop},
        fields=["user", "role"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )
    return shop_users


@frappe.whitelist()
def add_shop_user(user_email: str, role: str):
    """
    Adds a user to the current seller's shop with a specific role.
    """
    owner = frappe.session.user
    shop = _get_seller_shop(owner)

    user_to_add = frappe.db.get_value("User", {"email": user_email}, "name")
    if not user_to_add:
        frappe.throw("User not found.")

    if frappe.db.exists("User Shop", {"user": user_to_add, "shop": shop}):
        frappe.throw("User is already a member of this shop.")

    frappe.get_doc({
        "doctype": "User Shop",
        "user": user_to_add,
        "shop": shop,
        "role": role
    }).insert(ignore_permissions=True)

    return {"status": "success", "message": "User added to shop successfully."}


@frappe.whitelist()
def remove_shop_user(user_to_remove: str):
    """
    Removes a user from the current seller's shop.
    """
    owner = frappe.session.user
    shop = _get_seller_shop(owner)

    frappe.db.delete("User Shop", {"user": user_to_remove, "shop": shop})

    return {"status": "success", "message": "User removed from shop successfully."}


@frappe.whitelist()
def get_seller_invites():
    """
    Retrieves a list of invitations for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    invitations = frappe.get_all(
        "Invitation",
        filters={"shop": shop},
        fields=["user", "role", "status"]
    )
    return invitations


@frappe.whitelist()
def get_seller_kitchens(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of kitchens for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    kitchens = frappe.get_list(
        "Kitchen",
        filters={"shop": shop},
        fields=["name", "active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return kitchens


@frappe.whitelist()
def create_seller_kitchen(kitchen_data):
    """
    Creates a new kitchen for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(kitchen_data, str):
        kitchen_data = json.loads(kitchen_data)

    kitchen_data["shop"] = shop

    new_kitchen = frappe.get_doc({
        "doctype": "Kitchen",
        **kitchen_data
    })
    new_kitchen.insert(ignore_permissions=True)
    return new_kitchen.as_dict()


@frappe.whitelist()
def update_seller_kitchen(kitchen_name, kitchen_data):
    """
    Updates a kitchen for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(kitchen_data, str):
        kitchen_data = json.loads(kitchen_data)

    kitchen = frappe.get_doc("Kitchen", kitchen_name)

    if kitchen.shop != shop:
        frappe.throw("You are not authorized to update this kitchen.", frappe.PermissionError)

    kitchen.update(kitchen_data)
    kitchen.save(ignore_permissions=True)
    return kitchen.as_dict()


@frappe.whitelist()
def delete_seller_kitchen(kitchen_name):
    """
    Deletes a kitchen for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    kitchen = frappe.get_doc("Kitchen", kitchen_name)

    if kitchen.shop != shop:
        frappe.throw("You are not authorized to delete this kitchen.", frappe.PermissionError)

    frappe.delete_doc("Kitchen", kitchen_name, ignore_permissions=True)
    return {"status": "success", "message": "Kitchen deleted successfully."}


@frappe.whitelist()
def get_seller_coupons(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of coupons for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    coupons = frappe.get_list(
        "Coupon",
        filters={"shop": shop},
        fields=["name", "code", "quantity", "expired_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return coupons


@frappe.whitelist()
def create_seller_coupon(coupon_data):
    """
    Creates a new coupon for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(coupon_data, str):
        coupon_data = json.loads(coupon_data)

    coupon_data["shop"] = shop

    new_coupon = frappe.get_doc({
        "doctype": "Coupon",
        **coupon_data
    })
    new_coupon.insert(ignore_permissions=True)
    return new_coupon.as_dict()


@frappe.whitelist()
def update_seller_coupon(coupon_name, coupon_data):
    """
    Updates a coupon for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(coupon_data, str):
        coupon_data = json.loads(coupon_data)

    coupon = frappe.get_doc("Coupon", coupon_name)

    if coupon.shop != shop:
        frappe.throw("You are not authorized to update this coupon.", frappe.PermissionError)

    coupon.update(coupon_data)
    coupon.save(ignore_permissions=True)
    return coupon.as_dict()


@frappe.whitelist()
def delete_seller_coupon(coupon_name):
    """
    Deletes a coupon for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    coupon = frappe.get_doc("Coupon", coupon_name)

    if coupon.shop != shop:
        frappe.throw("You are not authorized to delete this coupon.", frappe.PermissionError)

    frappe.delete_doc("Coupon", coupon_name, ignore_permissions=True)
    return {"status": "success", "message": "Coupon deleted successfully."}


@frappe.whitelist()
def get_seller_discounts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of discounts for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    discounts = frappe.get_list(
        "Pricing Rule",
        filters={"shop": shop},
        fields=["name", "title", "apply_on", "valid_from", "valid_upto", "discount_percentage"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return discounts


@frappe.whitelist()
def create_seller_discount(discount_data):
    """
    Creates a new discount for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(discount_data, str):
        discount_data = json.loads(discount_data)

    discount_data["shop"] = shop

    new_discount = frappe.get_doc({
        "doctype": "Pricing Rule",
        **discount_data
    })
    new_discount.insert(ignore_permissions=True)
    return new_discount.as_dict()


@frappe.whitelist()
def update_seller_discount(discount_name, discount_data):
    """
    Updates a discount for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(discount_data, str):
        discount_data = json.loads(discount_data)

    discount = frappe.get_doc("Pricing Rule", discount_name)

    if discount.shop != shop:
        frappe.throw("You are not authorized to update this discount.", frappe.PermissionError)

    discount.update(discount_data)
    discount.save(ignore_permissions=True)
    return discount.as_dict()


@frappe.whitelist()
def delete_seller_discount(discount_name):
    """
    Deletes a discount for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    discount = frappe.get_doc("Pricing Rule", discount_name)

    if discount.shop != shop:
        frappe.throw("You are not authorized to delete this discount.", frappe.PermissionError)

    frappe.delete_doc("Pricing Rule", discount_name, ignore_permissions=True)
    return {"status": "success", "message": "Discount deleted successfully."}


@frappe.whitelist()
def get_seller_banners(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of banners for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    banners = frappe.get_list(
        "Banner",
        filters={"shop": shop},
        fields=["name", "title", "image", "link", "is_active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return banners


@frappe.whitelist()
def create_seller_banner(banner_data):
    """
    Creates a new banner for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(banner_data, str):
        banner_data = json.loads(banner_data)

    banner_data["shop"] = shop

    new_banner = frappe.get_doc({
        "doctype": "Banner",
        **banner_data
    })
    new_banner.insert(ignore_permissions=True)
    return new_banner.as_dict()


@frappe.whitelist()
def update_seller_banner(banner_name, banner_data):
    """
    Updates a banner for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(banner_data, str):
        banner_data = json.loads(banner_data)

    banner = frappe.get_doc("Banner", banner_name)

    if banner.shop != shop:
        frappe.throw("You are not authorized to update this banner.", frappe.PermissionError)

    banner.update(banner_data)
    banner.save(ignore_permissions=True)
    return banner.as_dict()


@frappe.whitelist()
def delete_seller_banner(banner_name):
    """
    Deletes a banner for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    banner = frappe.get_doc("Banner", banner_name)

    if banner.shop != shop:
        frappe.throw("You are not authorized to delete this banner.", frappe.PermissionError)

    frappe.delete_doc("Banner", banner_name, ignore_permissions=True)
    return {"status": "success", "message": "Banner deleted successfully."}


@frappe.whitelist()
def get_seller_extra_groups(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of product extra groups for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    extra_groups = frappe.get_list(
        "Product Extra Group",
        filters={"shop": shop},
        fields=["name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return extra_groups


@frappe.whitelist()
def create_seller_extra_group(group_data):
    """
    Creates a new product extra group for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(group_data, str):
        group_data = json.loads(group_data)

    group_data["shop"] = shop

    new_group = frappe.get_doc({
        "doctype": "Product Extra Group",
        **group_data
    })
    new_group.insert(ignore_permissions=True)
    return new_group.as_dict()


@frappe.whitelist()
def update_seller_extra_group(group_name, group_data):
    """
    Updates a product extra group for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(group_data, str):
        group_data = json.loads(group_data)

    group = frappe.get_doc("Product Extra Group", group_name)

    if group.shop != shop:
        frappe.throw("You are not authorized to update this group.", frappe.PermissionError)

    group.update(group_data)
    group.save(ignore_permissions=True)
    return group.as_dict()


@frappe.whitelist()
def delete_seller_extra_group(group_name):
    """
    Deletes a product extra group for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    group = frappe.get_doc("Product Extra Group", group_name)

    if group.shop != shop:
        frappe.throw("You are not authorized to delete this group.", frappe.PermissionError)

    frappe.delete_doc("Product Extra Group", group_name, ignore_permissions=True)
    return {"status": "success", "message": "Group deleted successfully."}


@frappe.whitelist()
def get_seller_extra_values(group_name, limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of product extra values for a given group.
    """
    extra_values = frappe.get_list(
        "Product Extra Value",
        filters={"product_extra_group": group_name},
        fields=["name", "value", "price"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return extra_values


@frappe.whitelist()
def create_seller_extra_value(value_data):
    """
    Creates a new product extra value.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(value_data, str):
        value_data = json.loads(value_data)

    group = frappe.get_doc("Product Extra Group", value_data["product_extra_group"])
    if group.shop != shop:
        frappe.throw("You are not authorized to add a value to this group.", frappe.PermissionError)

    new_value = frappe.get_doc({
        "doctype": "Product Extra Value",
        **value_data
    })
    new_value.insert(ignore_permissions=True)
    return new_value.as_dict()


@frappe.whitelist()
def update_seller_extra_value(value_name, value_data):
    """
    Updates a product extra value.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(value_data, str):
        value_data = json.loads(value_data)

    value = frappe.get_doc("Product Extra Value", value_name)
    group = frappe.get_doc("Product Extra Group", value.product_extra_group)

    if group.shop != shop:
        frappe.throw("You are not authorized to update this value.", frappe.PermissionError)

    value.update(value_data)
    value.save(ignore_permissions=True)
    return value.as_dict()


@frappe.whitelist()
def delete_seller_extra_value(value_name):
    """
    Deletes a product extra value.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    value = frappe.get_doc("Product Extra Value", value_name)
    group = frappe.get_doc("Product Extra Group", value.product_extra_group)

    if group.shop != shop:
        frappe.throw("You are not authorized to delete this value.", frappe.PermissionError)

    frappe.delete_doc("Product Extra Value", value_name, ignore_permissions=True)
    return {"status": "success", "message": "Value deleted successfully."}


@frappe.whitelist()
def get_seller_units(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of units for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    units = frappe.get_list(
        "Shop Unit",
        filters={"shop": shop},
        fields=["name", "active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return units


@frappe.whitelist()
def create_seller_unit(unit_data):
    """
    Creates a new unit for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(unit_data, str):
        unit_data = json.loads(unit_data)

    unit_data["shop"] = shop

    new_unit = frappe.get_doc({
        "doctype": "Shop Unit",
        **unit_data
    })
    new_unit.insert(ignore_permissions=True)
    return new_unit.as_dict()


@frappe.whitelist()
def update_seller_unit(unit_name, unit_data):
    """
    Updates a unit for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(unit_data, str):
        unit_data = json.loads(unit_data)

    unit = frappe.get_doc("Shop Unit", unit_name)

    if unit.shop != shop:
        frappe.throw("You are not authorized to update this unit.", frappe.PermissionError)

    unit.update(unit_data)
    unit.save(ignore_permissions=True)
    return unit.as_dict()


@frappe.whitelist()
def delete_seller_unit(unit_name):
    """
    Deletes a unit for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    unit = frappe.get_doc("Shop Unit", unit_name)

    if unit.shop != shop:
        frappe.throw("You are not authorized to delete this unit.", frappe.PermissionError)

    frappe.delete_doc("Shop Unit", unit_name, ignore_permissions=True)
    return {"status": "success", "message": "Unit deleted successfully."}


@frappe.whitelist()
def get_seller_tags(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of tags for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    tags = frappe.get_list(
        "Shop Tag",
        filters={"shop": shop},
        fields=["name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return tags


@frappe.whitelist()
def create_seller_tag(tag_data):
    """
    Creates a new tag for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(tag_data, str):
        tag_data = json.loads(tag_data)

    tag_data["shop"] = shop

    new_tag = frappe.get_doc({
        "doctype": "Shop Tag",
        **tag_data
    })
    new_tag.insert(ignore_permissions=True)
    return new_tag.as_dict()


@frappe.whitelist()
def update_seller_tag(tag_name, tag_data):
    """
    Updates a tag for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(tag_data, str):
        tag_data = json.loads(tag_data)

    tag = frappe.get_doc("Shop Tag", tag_name)

    if tag.shop != shop:
        frappe.throw("You are not authorized to update this tag.", frappe.PermissionError)

    tag.update(tag_data)
    tag.save(ignore_permissions=True)
    return tag.as_dict()


@frappe.whitelist()
def delete_seller_tag(tag_name):
    """
    Deletes a tag for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    tag = frappe.get_doc("Shop Tag", tag_name)

    if tag.shop != shop:
        frappe.throw("You are not authorized to delete this tag.", frappe.PermissionError)

    frappe.delete_doc("Shop Tag", tag_name, ignore_permissions=True)
    return {"status": "success", "message": "Tag deleted successfully."}


@frappe.whitelist()
def get_seller_transactions(limit_start=0, limit_page_length=20):
    """
    Retrieves a list of transactions for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all(
        "Order",
        filters={"shop": shop},
        pluck="name"
    )

    if not orders:
        return []

    transactions = frappe.get_all(
        "Transaction",
        filters={"reference_name": ["in", orders]},
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "debit", "credit", "currency"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return transactions


@frappe.whitelist()
def get_seller_shop_payments(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of shop payments for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all(
        "Order",
        filters={"shop": shop},
        pluck="name"
    )

    if not orders:
        return []

    payments = frappe.get_all(
        "Transaction",
        filters={
            "reference_name": ["in", orders],
            "credit": [">", 0]
        },
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "credit", "currency"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return payments


@frappe.whitelist()
def get_seller_payouts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of payouts for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    payouts = frappe.get_list(
        "Seller Payout",
        filters={"shop": shop},
        fields=["name", "amount", "payout_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payout_date desc"
    )
    return payouts


@frappe.whitelist()
def get_seller_bonuses(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of bonuses for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    bonuses = frappe.get_list(
        "Shop Bonus",
        filters={"shop": shop},
        fields=["name", "amount", "bonus_date", "reason"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="bonus_date desc"
    )
    return bonuses


@frappe.whitelist()
def get_seller_stories(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of stories for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    stories = frappe.get_list(
        "Story",
        filters={"shop": shop},
        fields=["name", "title", "image", "expires_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return stories


@frappe.whitelist()
def create_seller_story(story_data):
    """
    Creates a new story for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(story_data, str):
        story_data = json.loads(story_data)

    story_data["shop"] = shop

    new_story = frappe.get_doc({
        "doctype": "Story",
        **story_data
    })
    new_story.insert(ignore_permissions=True)
    return new_story.as_dict()


@frappe.whitelist()
def update_seller_story(story_name, story_data):
    """
    Updates a story for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(story_data, str):
        story_data = json.loads(story_data)

    story = frappe.get_doc("Story", story_name)

    if story.shop != shop:
        frappe.throw("You are not authorized to update this story.", frappe.PermissionError)

    story.update(story_data)
    story.save(ignore_permissions=True)
    return story.as_dict()


@frappe.whitelist()
def delete_seller_story(story_name):
    """
    Deletes a story for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    story = frappe.get_doc("Story", story_name)

    if story.shop != shop:
        frappe.throw("You are not authorized to delete this story.", frappe.PermissionError)

    frappe.delete_doc("Story", story_name, ignore_permissions=True)
    return {"status": "success", "message": "Story deleted successfully."}


@frappe.whitelist()
def get_seller_shop_galleries(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of shop gallery images for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    galleries = frappe.get_list(
        "Shop Gallery",
        filters={"shop": shop},
        fields=["name", "image"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return galleries


@frappe.whitelist()
def create_seller_shop_gallery(gallery_data):
    """
    Creates a new shop gallery image for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(gallery_data, str):
        gallery_data = json.loads(gallery_data)

    gallery_data["shop"] = shop

    new_gallery = frappe.get_doc({
        "doctype": "Shop Gallery",
        **gallery_data
    })
    new_gallery.insert(ignore_permissions=True)
    return new_gallery.as_dict()


@frappe.whitelist()
def delete_seller_shop_gallery(gallery_name):
    """
    Deletes a shop gallery image for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    gallery = frappe.get_doc("Shop Gallery", gallery_name)

    if gallery.shop != shop:
        frappe.throw("You are not authorized to delete this gallery image.", frappe.PermissionError)

    frappe.delete_doc("Shop Gallery", gallery_name, ignore_permissions=True)
    return {"status": "success", "message": "Gallery image deleted successfully."}


@frappe.whitelist()
def get_seller_menus(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of menus for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    menus = frappe.get_list(
        "Menu",
        filters={"shop": shop},
        fields=["name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return menus


@frappe.whitelist()
def get_seller_menu(menu_name):
    """
    Retrieves a single menu with its items for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    menu = frappe.get_doc("Menu", menu_name)

    if menu.shop != shop:
        frappe.throw("You are not authorized to view this menu.", frappe.PermissionError)

    return menu.as_dict()


@frappe.whitelist()
def create_seller_menu(menu_data):
    """
    Creates a new menu for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(menu_data, str):
        menu_data = json.loads(menu_data)

    menu_data["shop"] = shop

    new_menu = frappe.get_doc({
        "doctype": "Menu",
        **menu_data
    })
    new_menu.insert(ignore_permissions=True)
    return new_menu.as_dict()


@frappe.whitelist()
def update_seller_menu(menu_name, menu_data):
    """
    Updates a menu for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(menu_data, str):
        menu_data = json.loads(menu_data)

    menu = frappe.get_doc("Menu", menu_name)

    if menu.shop != shop:
        frappe.throw("You are not authorized to update this menu.", frappe.PermissionError)

    menu.update(menu_data)
    menu.save(ignore_permissions=True)
    return menu.as_dict()


@frappe.whitelist()
def delete_seller_menu(menu_name):
    """
    Deletes a menu for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    menu = frappe.get_doc("Menu", menu_name)

    if menu.shop != shop:
        frappe.throw("You are not authorized to delete this menu.", frappe.PermissionError)

    frappe.delete_doc("Menu", menu_name, ignore_permissions=True)
    return {"status": "success", "message": "Menu deleted successfully."}


@frappe.whitelist()
def get_seller_order_refunds(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of order refunds for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all("Order", filters={"shop": shop}, pluck="name")

    if not orders:
        return []

    refunds = frappe.get_list(
        "Order Refund",
        filters={"order": ["in", orders]},
        fields=["name", "order", "status", "cause", "answer"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return refunds


@frappe.whitelist()
def update_seller_order_refund(refund_name, status, answer=None):
    """
    Updates the status and answer of an order refund.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    refund = frappe.get_doc("Order Refund", refund_name)
    order = frappe.get_doc("Order", refund.order)

    if order.shop != shop:
        frappe.throw("You are not authorized to update this refund request.", frappe.PermissionError)

    if status not in ["Accepted", "Canceled"]:
        frappe.throw("Invalid status. Must be 'Accepted' or 'Canceled'.")

    refund.status = status
    if answer:
        refund.answer = answer

    refund.save(ignore_permissions=True)
    return refund.as_dict()


@frappe.whitelist()
def get_seller_reviews(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of reviews for products in the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    products = frappe.get_all("Item", filters={"shop": shop}, pluck="name")

    if not products:
        return []

    reviews = frappe.get_list(
        "Review",
        filters={"reviewable_id": ["in", products], "reviewable_type": "Item"},
        fields=["name", "user", "rating", "comment", "creation", "reviewable_id"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return reviews


@frappe.whitelist()
def get_seller_delivery_zones(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of delivery zones for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    delivery_zones = frappe.get_list(
        "Delivery Zone",
        filters={"shop": shop},
        fields=["name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return delivery_zones


@frappe.whitelist()
def get_seller_delivery_zone(zone_name):
    """
    Retrieves a single delivery zone with its coordinates for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    zone = frappe.get_doc("Delivery Zone", zone_name)

    if zone.shop != shop:
        frappe.throw("You are not authorized to view this delivery zone.", frappe.PermissionError)

    return zone.as_dict()


@frappe.whitelist()
def create_seller_delivery_zone(zone_data):
    """
    Creates a new delivery zone for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(zone_data, str):
        zone_data = json.loads(zone_data)

    zone_data["shop"] = shop

    new_zone = frappe.get_doc({
        "doctype": "Delivery Zone",
        **zone_data
    })
    new_zone.insert(ignore_permissions=True)
    return new_zone.as_dict()


@frappe.whitelist()
def update_seller_delivery_zone(zone_name, zone_data):
    """
    Updates a delivery zone for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(zone_data, str):
        zone_data = json.loads(zone_data)

    zone = frappe.get_doc("Delivery Zone", zone_name)

    if zone.shop != shop:
        frappe.throw("You are not authorized to update this delivery zone.", frappe.PermissionError)

    zone.update(zone_data)
    zone.save(ignore_permissions=True)
    return zone.as_dict()


@frappe.whitelist()
def delete_seller_delivery_zone(zone_name):
    """
    Deletes a delivery zone for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    zone = frappe.get_doc("Delivery Zone", zone_name)

    if zone.shop != shop:
        frappe.throw("You are not authorized to delete this delivery zone.", frappe.PermissionError)

    frappe.delete_doc("Delivery Zone", zone_name, ignore_permissions=True)
    return {"status": "success", "message": "Delivery zone deleted successfully."}


@frappe.whitelist()
def get_seller_branches(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of branches for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    branches = frappe.get_list(
        "Branch",
        filters={"shop": shop},
        fields=["name", "branch_name", "address", "latitude", "longitude"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return branches


@frappe.whitelist()
def create_seller_branch(branch_data):
    """
    Creates a new branch for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(branch_data, str):
        branch_data = json.loads(branch_data)

    branch_data["shop"] = shop
    branch_data["owner"] = user

    new_branch = frappe.get_doc({
        "doctype": "Branch",
        **branch_data
    })
    new_branch.insert(ignore_permissions=True)
    return new_branch.as_dict()


@frappe.whitelist()
def update_seller_branch(branch_name, branch_data):
    """
    Updates a branch for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(branch_data, str):
        branch_data = json.loads(branch_data)

    branch = frappe.get_doc("Branch", branch_name)

    if branch.shop != shop:
        frappe.throw("You are not authorized to update this branch.", frappe.PermissionError)

    branch.update(branch_data)
    branch.save(ignore_permissions=True)
    return branch.as_dict()


@frappe.whitelist()
def delete_seller_branch(branch_name):
    """
    Deletes a branch for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    branch = frappe.get_doc("Branch", branch_name)

    if branch.shop != shop:
        frappe.throw("You are not authorized to delete this branch.", frappe.PermissionError)

    frappe.delete_doc("Branch", branch_name, ignore_permissions=True)
    return {"status": "success", "message": "Branch deleted successfully."}

@frappe.whitelist()
def get_seller_deliveryman_settings():
    """
    Retrieves the deliveryman settings for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if not frappe.db.exists("Shop Deliveryman Settings", {"shop": shop}):
        return {}

    return frappe.get_doc("Shop Deliveryman Settings", {"shop": shop}).as_dict()


@frappe.whitelist()
def update_seller_deliveryman_settings(settings_data):
    """
    Updates the deliveryman settings for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(settings_data, str):
        settings_data = json.loads(settings_data)

    if not frappe.db.exists("Shop Deliveryman Settings", {"shop": shop}):
        settings = frappe.new_doc("Shop Deliveryman Settings")
        settings.shop = shop
    else:
        settings = frappe.get_doc("Shop Deliveryman Settings", {"shop": shop})

    settings.update(settings_data)
    settings.save(ignore_permissions=True)
    return settings.as_dict()


@frappe.whitelist()
def get_seller_inventory_items(limit_start: int = 0, limit_page_length: int = 20, item_code: str = None):
    """
    Retrieves inventory items (Bin entries) for the current seller's shop.
    Can be filtered by a specific item.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    item_filters = {"shop": shop}
    if item_code:
        item_filters["name"] = item_code

    items = frappe.get_all("Item", filters=item_filters, pluck="name")

    if not items:
        return []

    inventory_items = frappe.get_list(
        "Bin",
        filters={"item_code": ["in", items]},
        fields=["item_code", "warehouse", "actual_qty"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )
    return inventory_items
    user = frappe.session.user
    shop = _get_seller_shop(user)

    products = frappe.get_all(
        "Item",
        filters={"shop": shop},
        fields=["name", "item_name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )

    product_names = [p['name'] for p in products]

    if not product_names:
        return []

    stock_levels = frappe.get_all(
        "Bin",
        fields=["item_code", "actual_qty"],
        filters={"item_code": ["in", product_names]}
    )

    stock_map = {s['item_code']: s['actual_qty'] for s in stock_levels}

    for p in products:
        p['stock_quantity'] = stock_map.get(p.name, 0)

    return products


@frappe.whitelist()
def get_ads_packages():
    """
    Retrieves a list of available ads packages.
    """
    return frappe.get_list(
        "Ads Package",
        fields=["name", "price", "duration_days"]
    )


@frappe.whitelist()
def get_seller_shop_ads_packages(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of purchased ads packages for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    shop_ads_packages = frappe.get_list(
        "Shop Ads Package",
        filters={"shop": shop},
        fields=["name", "ads_package", "start_date", "end_date"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="end_date desc"
    )
    return shop_ads_packages


@frappe.whitelist()
def purchase_shop_ads_package(package_name):
    """
    Purchases an ads package for the current seller's shop, including
    subscription validation and payment processing.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to purchase an add-on.")

    shop = _get_seller_shop(user)
    ads_package = frappe.get_doc("Ads Package", package_name)

    # 1. Check subscription eligibility
    subscription_details = get_subscription_details()
    current_plan = subscription_details.get("plan")

    eligible_plans = [plan.subscription_plan for plan in ads_package.get("eligible_plans", [])]

    # If the eligible_plans list is not empty, we must enforce it.
    if eligible_plans and current_plan not in eligible_plans:
        frappe.throw(
            "Your current subscription plan is not eligible to purchase this add-on.",
            title="Upgrade Required"
        )

    # 2. Initiate payment via the control panel
    control_plane_url = frappe.conf.get("control_plane_url")
    api_secret = frappe.conf.get("api_secret")

    if not control_plane_url or not api_secret:
        frappe.log_error("Tenant site is not configured to communicate with the control panel.", "Add-on Purchase Error")
        frappe.throw("Platform communication is not configured. Cannot process payment.", title="Configuration Error")

    customer_email = frappe.get_value("User", user, "email")

    scheme = frappe.conf.get("control_plane_scheme", "https")
    api_url = f"{scheme}://{control_plane_url}/api/method/rokct.rokct.control_panel.billing.charge_customer_for_addon"

    headers = {
        "X-Rokct-Secret": api_secret,
        "Content-Type": "application/json"
    }

    payment_data = {
        "customer_email": customer_email,
        "amount": ads_package.price,
        "currency": "USD",
        "addon_name": ads_package.name
    }

    try:
        response = frappe.make_post_request(api_url, headers=headers, data=json.dumps(payment_data))
        if response.get("status") != "success":
            frappe.throw(response.get("message", "Payment failed."), title="Payment Error")

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Add-on Payment Failed")
        frappe.throw(f"An error occurred while processing the payment: {e}")

    # 3. If payment is successful, create the Shop Ads Package
    from frappe.utils import nowdate, add_days

    start_date = nowdate()
    end_date = add_days(start_date, ads_package.duration_days)

    new_shop_ads_package = frappe.get_doc({
        "doctype": "Shop Ads Package",
        "shop": shop,
        "ads_package": package_name,
        "start_date": start_date,
        "end_date": end_date
    })
    new_shop_ads_package.insert(ignore_permissions=True)
    frappe.db.commit()

    return new_shop_ads_package.as_dict()


@frappe.whitelist()
def get_seller_receipts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of receipts for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    receipts = frappe.get_list(
        "Receipt",
        filters={"shop": shop},
        fields=["name", "title"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return receipts


@frappe.whitelist()
def create_seller_receipt(receipt_data):
    """
    Creates a new receipt for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(receipt_data, str):
        receipt_data = json.loads(receipt_data)

    receipt_data["shop"] = shop

    new_receipt = frappe.get_doc({
        "doctype": "Receipt",
        **receipt_data
    })
    new_receipt.insert(ignore_permissions=True)
    return new_receipt.as_dict()


@frappe.whitelist()
def update_seller_receipt(receipt_name, receipt_data):
    """
    Updates a receipt for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(receipt_data, str):
        receipt_data = json.loads(receipt_data)

    receipt = frappe.get_doc("Receipt", receipt_name)

    if receipt.shop != shop:
        frappe.throw("You are not authorized to update this receipt.", frappe.PermissionError)

    receipt.update(receipt_data)
    receipt.save(ignore_permissions=True)
    return receipt.as_dict()


@frappe.whitelist()
def delete_seller_receipt(receipt_name):
    """
    Deletes a receipt for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    receipt = frappe.get_doc("Receipt", receipt_name)

    if receipt.shop != shop:
        frappe.throw("You are not authorized to delete this receipt.", frappe.PermissionError)

    frappe.delete_doc("Receipt", receipt_name, ignore_permissions=True)
    return {"status": "success", "message": "Receipt deleted successfully."}


@frappe.whitelist()
def get_seller_combos(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of combos for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    combos = frappe.get_list(
        "Combo",
        filters={"shop": shop},
        fields=["name", "price"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return combos


@frappe.whitelist()
def get_seller_combo(combo_name):
    """
    Retrieves a single combo with its items for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    combo = frappe.get_doc("Combo", combo_name)

    if combo.shop != shop:
        frappe.throw("You are not authorized to view this combo.", frappe.PermissionError)

    return combo.as_dict()


@frappe.whitelist()
def create_seller_combo(combo_data):
    """
    Creates a new combo for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(combo_data, str):
        combo_data = json.loads(combo_data)

    combo_data["shop"] = shop

    new_combo = frappe.get_doc({
        "doctype": "Combo",
        **combo_data
    })
    new_combo.insert(ignore_permissions=True)
    return new_combo.as_dict()


@frappe.whitelist()
def update_seller_combo(combo_name, combo_data):
    """
    Updates a combo for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(combo_data, str):
        combo_data = json.loads(combo_data)

    combo = frappe.get_doc("Combo", combo_name)

    if combo.shop != shop:
        frappe.throw("You are not authorized to update this combo.", frappe.PermissionError)

    combo.update(combo_data)
    combo.save(ignore_permissions=True)
    return combo.as_dict()


@frappe.whitelist()
def delete_seller_combo(combo_name):
    """
    Deletes a combo for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    combo = frappe.get_doc("Combo", combo_name)

    if combo.shop != shop:
        frappe.throw("You are not authorized to delete this combo.", frappe.PermissionError)

    frappe.delete_doc("Combo", combo_name, ignore_permissions=True)
    return {"status": "success", "message": "Combo deleted successfully."}


@frappe.whitelist()
def get_seller_request_models(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of request models for the current seller.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your request models.", frappe.AuthenticationError)

    request_models = frappe.get_list(
        "Request Model",
        filters={"created_by_user": user},
        fields=["name", "model_type", "model", "status", "created_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return request_models

@frappe.whitelist()
def get_seller_customer_addresses(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of customer addresses for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    customer_ids = frappe.db.sql_list("""
        SELECT DISTINCT user FROM `tabOrder` WHERE shop = %(shop)s
    """, {"shop": shop})

    if not customer_ids:
        return []

    addresses = frappe.get_all(
        "User Address",
        filters={"user": ["in", customer_ids]},
        fields=["name", "user", "title", "address", "location", "active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )
    return addresses

@frappe.whitelist()
def get_seller_payment_to_partners(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of payments to partners for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    payouts = frappe.get_list(
        "Payout",
        filters={"shop": shop},
        fields=["name", "deliveryman", "amount", "payment_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payment_date desc"
    )
    return payouts


@frappe.whitelist()
def get_seller_delivery_man_delivery_zones(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of delivery zones for the deliverymen of the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    deliverymen = frappe.db.sql_list("""
        SELECT DISTINCT deliveryman FROM `tabOrder` WHERE shop = %(shop)s AND deliveryman IS NOT NULL
    """, {"shop": shop})

    if not deliverymen:
        return []

    delivery_zones = frappe.get_list(
        "Deliveryman Delivery Zone",
        filters={"deliveryman": ["in", deliverymen]},
        fields=["name", "deliveryman", "delivery_zone"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )
    return delivery_zones

@frappe.whitelist()
def adjust_seller_inventory(item_code: str, warehouse: str, new_qty: int):
    """
    Adjusts the inventory for a specific item in a warehouse for the current seller's shop.
    """
    user = frappe.session.user
    shop = _get_seller_shop(user)

    item = frappe.get_doc("Item", item_code)
    if item.shop != shop:
        frappe.throw("You are not authorized to adjust inventory for this item.", frappe.PermissionError)

    # Get current quantity
    current_qty = frappe.db.get_value("Bin", {"item_code": item_code, "warehouse": warehouse}, "actual_qty") or 0

    # Create a stock reconciliation entry
    stock_entry = frappe.get_doc({
        "doctype": "Stock Entry",
        "purpose": "Stock Reconciliation",
        "company": shop,
        "items": [{
            "item_code": item_code,
            "warehouse": warehouse,
            "qty": new_qty,
            "basic_rate": item.standard_rate,
            "t_warehouse": warehouse,
            "s_warehouse": warehouse,
            "diff_qty": new_qty - current_qty
        }]
    })
    stock_entry.submit()

    return {"status": "success", "message": f"Inventory for {item_code} adjusted to {new_qty}."}