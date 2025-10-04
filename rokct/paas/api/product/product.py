import frappe
import json

@frappe.whitelist(allow_guest=True)
def get_products(
    limit_start: int = 0,
    limit_page_length: int = 20,
    category_id: str = None,
    brand_id: str = None,
    shop_id: str = None,
    order_by: str = None,  # new, old, best_sale, low_sale, high_rating, low_rating
    rating: str = None,  # e.g. "1,5"
    search: str = None,
):
    """
    Retrieves a list of products (Items) with pagination, advanced filters, and sorting.
    """
    params = {}
    conditions = [
        "t_item.disabled = 0",
        "t_item.has_variants = 0",
        # Assuming is_visible_in_website is the correct field for frontend visibility
        "t_item.is_visible_in_website = 1",
        "t_item.status = 'Published'",
    ]

    if category_id:
        conditions.append("t_item.item_group = %(category_id)s")
        params["category_id"] = category_id

    if brand_id:
        conditions.append("t_item.brand = %(brand_id)s")
        params["brand_id"] = brand_id

    if shop_id:
        conditions.append("t_item.shop = %(shop_id)s")
        params["shop_id"] = shop_id

    if search:
        conditions.append("t_item.item_name LIKE %(search)s")
        params["search"] = f"%{search}%"

    # --- Joins and Ordering Logic ---
    joins = ""
    order_by_clause = "ORDER BY t_item.creation DESC"  # Default order

    # Rating filter and sorting
    if rating or order_by in ["high_rating", "low_rating"]:
        joins += """
            LEFT JOIN (
                SELECT parent, AVG(rating) as avg_rating
                FROM `tabReview`
                WHERE parenttype = 'Item'
                GROUP BY parent
            ) AS t_reviews ON t_reviews.parent = t_item.name
        """
        if rating:
            try:
                min_rating, max_rating = map(float, rating.split(','))
                conditions.append("t_reviews.avg_rating BETWEEN %(min_rating)s AND %(max_rating)s")
                params["min_rating"] = min_rating
                params["max_rating"] = max_rating
            except (ValueError, IndexError):
                pass  # Ignore invalid rating format

        if order_by in ["high_rating", "low_rating"]:
            sort_dir = "DESC" if order_by == "high_rating" else "ASC"
            # Ensure items with no reviews are last when sorting
            order_by_clause = f"ORDER BY t_reviews.avg_rating IS NULL, t_reviews.avg_rating {sort_dir}"

    # Sales-based sorting
    elif order_by in ["best_sale", "low_sale"]:
        joins += """
            LEFT JOIN (
                SELECT item_code, SUM(qty) as total_qty
                FROM `tabSales Invoice Item`
                GROUP BY item_code
            ) AS t_sales ON t_sales.item_code = t_item.name
        """
        sort_dir = "DESC" if order_by == "best_sale" else "ASC"
        order_by_clause = f"ORDER BY t_sales.total_qty IS NULL, t_sales.total_qty {sort_dir}"

    elif order_by == "new":
        order_by_clause = "ORDER BY t_item.creation DESC"
    elif order_by == "old":
        order_by_clause = "ORDER BY t_item.creation ASC"

    # --- Build and Execute Query ---
    where_clause = " AND ".join(conditions)
    params.update({"limit_page_length": limit_page_length, "limit_start": limit_start})

    query = f"""
        SELECT
            t_item.name, t_item.item_name, t_item.description, t_item.image,
            t_item.standard_rate
        FROM `tabItem` AS t_item
        {joins}
        WHERE {where_clause}
        {order_by_clause}
        LIMIT %(limit_page_length)s OFFSET %(limit_start)s
    """

    products = frappe.db.sql(query, params, as_dict=True)

    if not products:
        return []

    # --- Eager Loading for Performance ---
    product_names = [p['name'] for p in products]

    # Get stock levels
    stocks = frappe.get_all(
        "Bin", fields=["item_code", "actual_qty"],
        filters={"item_code": ["in", product_names], "actual_qty": [">", 0]}
    )
    stocks_map = {s['item_code']: s['actual_qty'] for s in stocks}

    # Get active discounts
    today = frappe.utils.nowdate()
    pricing_rules = frappe.get_all(
        "Pricing Rule",
        filters={"disable": 0, "valid_from": ["<=", today], "valid_upto": [">=", today],
                 "apply_on": "Item Code", "item_code": ["in", product_names]},
        fields=["item_code", "rate_or_discount", "discount_percentage"]
    )
    discounts_map = {rule['item_code']: rule for rule in pricing_rules}

    # Get review averages and counts
    reviews_data = frappe.db.sql(f"""
        SELECT `parent`, AVG(`rating`) as avg_rating, COUNT(*) as reviews_count
        FROM `tabReview`
        WHERE `parenttype` = 'Item' AND `parent` IN %(product_names)s
        GROUP BY `parent`
    """, {"product_names": product_names}, as_dict=True)
    reviews_map = {r['parent']: r for r in reviews_data}

    # --- Assemble Final Response ---
    for p in products:
        p['stock_quantity'] = stocks_map.get(p.name, 0)
        p['discount'] = discounts_map.get(p.name)
        p['reviews'] = reviews_map.get(p.name, {"avg_rating": 0, "reviews_count": 0})

    return products


@frappe.whitelist(allow_guest=True)
def most_sold_products(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of most sold products.
    """
    most_sold_items = frappe.db.sql("""
        SELECT item_code, SUM(qty) as total_qty
        FROM `tabSales Invoice Item`
        GROUP BY item_code
        ORDER BY total_qty DESC
        LIMIT %(limit_page_length)s
        OFFSET %(limit_start)s
    """, {"limit_start": limit_start, "limit_page_length": limit_page_length}, as_dict=True)

    item_codes = [d.item_code for d in most_sold_items]

    if not item_codes:
        return []

    return frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"name": ("in", item_codes)},
        order_by="name"
    )


@frappe.whitelist(allow_guest=True)
def get_discounted_products(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of products with active discounts.
    """
    today = frappe.utils.nowdate()

    # Get all active pricing rules
    active_rules = frappe.get_all(
        "Pricing Rule",
        filters={
            "disable": 0,
            "valid_from": ("<=", today),
            "valid_upto": (">=", today),
        },
        fields=["name", "apply_on", "item_code", "item_group", "brand"]
    )

    item_codes = set()

    for rule in active_rules:
        if rule.apply_on == 'Item Code' and rule.item_code:
            item_codes.add(rule.item_code)
        elif rule.apply_on == 'Item Group' and rule.item_group:
            items_in_group = frappe.get_all("Item", filters={"item_group": rule.item_group}, pluck="name")
            item_codes.update(items_in_group)
        elif rule.apply_on == 'Brand' and rule.brand:
            items_in_brand = frappe.get_all("Item", filters={"brand": rule.brand}, pluck="name")
            item_codes.update(items_in_brand)

    if not item_codes:
        return []

    # Paginate on the final list of item codes
    paginated_item_codes = list(item_codes)[limit_start : limit_start + limit_page_length]

    if not paginated_item_codes:
        return []

    return frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"name": ("in", paginated_item_codes)},
        order_by="name"
    )


@frappe.whitelist(allow_guest=True)
def get_products_by_ids(ids: list):
    """
    Retrieves a list of products by their IDs.
    """
    if not ids:
        return []

    return frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"name": ("in", ids)},
        order_by="name"
    )


@frappe.whitelist(allow_guest=True)
def get_product_by_uuid(uuid: str):
    """
    Retrieves a single product by its UUID.
    """
    product = frappe.get_doc("Item", {"uuid": uuid})
    return product.as_dict()


@frappe.whitelist(allow_guest=True)
def get_product_by_slug(slug: str):
    """
    Retrieves a single product by its slug.
    """
    product = frappe.get_doc("Item", {"route": slug})
    return product.as_dict()


@frappe.whitelist(allow_guest=True)
def read_product_file(uuid: str):
    """
    Reads a product file.
    """
    product = frappe.get_doc("Item", {"uuid": uuid})
    if not product.image:
        frappe.throw("Product does not have an image.")

    try:
        file = frappe.get_doc("File", {"file_url": product.image})
        return file.get_content()
    except frappe.DoesNotExistError:
        frappe.throw("File not found.")


@frappe.whitelist(allow_guest=True)
def get_product_reviews(uuid: str, limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves reviews for a specific product by its UUID.
    """
    product_name = frappe.db.get_value("Item", {"uuid": uuid}, "name")
    if not product_name:
        frappe.throw("Product not found.")

    reviews = frappe.get_list(
        "Review",
        fields=["name", "user", "rating", "comment", "creation"],
        filters={
            "reviewable_type": "Item",
            "reviewable_id": product_name,
            "published": 1
        },
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return reviews


@frappe.whitelist(allow_guest=True)
def order_products_calculate(products: list):
    """
    Calculates the total price of a list of products.
    """
    total_price = 0
    for product in products:
        item = frappe.get_doc("Item", product.get("product_id"))
        total_price += item.standard_rate * product.get("quantity", 1)
    return {"total_price": total_price}


@frappe.whitelist(allow_guest=True)
def get_products_by_brand(brand_id: str, limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of products for a given brand.
    """
    products = frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"brand": brand_id},
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return products


@frappe.whitelist(allow_guest=True)
def products_search(search: str, limit_start: int = 0, limit_page_length: int = 20):
    """
    Searches for products by a search term.
    """
    products = frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters=[
            ["Item", "item_name", "like", f"%{search}%"],
        ],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return products


@frappe.whitelist(allow_guest=True)
def get_products_by_category(uuid: str, limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of products for a given category.
    """
    category_name = frappe.db.get_value("Category", {"uuid": uuid}, "name")
    if not category_name:
        frappe.throw("Category not found.")

    products = frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"item_group": category_name},
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return products


@frappe.whitelist(allow_guest=True)
def get_products_by_shop(shop_id: str, limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of products for a given shop.
    """
    products = frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"shop": shop_id},
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name"
    )
    return products


@frappe.whitelist()
def add_product_review(uuid: str, rating: float, comment: str = None):
    """
    Adds a review for a product by its UUID, but only if the user has purchased it.
    """
    user = frappe.session.user

    if user == "Guest":
        frappe.throw("You must be logged in to leave a review.")

    product_name = frappe.db.get_value("Item", {"uuid": uuid}, "name")
    if not product_name:
        frappe.throw("Product not found.")

    # Check if user has purchased this item
    has_purchased = frappe.db.exists(
        "Sales Invoice Item",
        {
            "item_code": product_name,
            "parent": ("in", frappe.get_all("Sales Invoice", filters={"customer": user}, pluck="name"))
        }
    )

    if not has_purchased:
        frappe.throw("You can only review products you have purchased.")

    # Check if user has already reviewed this item
    if frappe.db.exists("Review", {"reviewable_type": "Item", "reviewable_id": product_name, "user": user}):
        frappe.throw("You have already reviewed this product.")

    review = frappe.get_doc({
        "doctype": "Review",
        "reviewable_type": "Item",
        "reviewable_id": product_name,
        "user": user,
        "rating": rating,
        "comment": comment,
        "published": 1
    })
    review.insert(ignore_permissions=True)
    return review.as_dict()


@frappe.whitelist()
def get_product_history(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves the viewing history for the current user, specific to products (Items).
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your history.")

    # Get the names of the items the user has viewed
    viewed_item_names = frappe.get_all(
        "View Log",
        filters={
            "user": user,
            "doctype": "Item"
        },
        fields=["docname"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        distinct=True
    )

    item_names = [d.docname for d in viewed_item_names]

    if not item_names:
        return []

    # Fetch the actual product details for the viewed items
    products = frappe.get_list(
        "Item",
        fields=["name", "item_name", "description", "image", "standard_rate"],
        filters={"name": ("in", item_names)},
    )

    return products