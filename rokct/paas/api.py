# Copyright (c) 2025 ROKCT Holdings
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import frappe
import random
from rokct.rokct.utils.subscription_checker import check_subscription_feature
from frappe.model.document import Document
import json
import uuid
import csv
import io

@frappe.whitelist()
def get_weather(location: str):
    """
    Proxy endpoint to get weather data from the control site, with tenant-side caching.
    This follows the same authentication pattern as other tenant-to-control-panel APIs.
    """
    if not location:
        frappe.throw("Location is a required parameter.")

    # Use a different cache key for the proxy to avoid conflicts
    cache_key = f"weather_proxy_{location.lower().replace(' ', '_')}"
    cached_data = frappe.cache().get_value(cache_key)

    if cached_data:
        return cached_data

    # Get connection details from site config (set during tenant provisioning)
    control_plane_url = frappe.conf.get("control_plane_url")
    api_secret = frappe.conf.get("api_secret")

    if not control_plane_url or not api_secret:
        frappe.log_error("Tenant site is not configured to communicate with the control panel.", "Weather Proxy Error")
        frappe.throw("Platform communication is not configured.", title="Configuration Error")

    # Construct the secure API call
    scheme = frappe.conf.get("control_plane_scheme", "https")
    api_url = f"{scheme}://{control_plane_url}/api/method/rokct.rokct.api.get_weather"
    headers = {
        "Authorization": f"Bearer {api_secret}",
        "Accept": "application/json"
    }

    try:
        # Use frappe.make_get_request which is a wrapper around requests
        # and handles logging and exceptions in a standard way.
        response = frappe.make_get_request(api_url, headers=headers, params={"location": location})

        # Cache the successful response for 10 minutes on the tenant site
        frappe.cache().set_value(cache_key, response, expires_in_sec=600)

        return response

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Weather Proxy API Error")
        frappe.throw(f"An error occurred while fetching weather data from the control plane: {e}")

@frappe.whitelist()
def logout():
    """
    Log out the current user.
    """
    frappe.logout()
    return {"status": "success", "message": "User successfully logout"}


@frappe.whitelist()
@check_subscription_feature("phone_verification")
def check_phone(phone: str):
    """
    Check if a phone number is already registered to a user.
    """
    if not phone:
        frappe.throw("Phone number is a required parameter.")

    if frappe.db.exists("User", {"phone": phone}):
        return {"status": "error", "message": "Phone number already exists."}
    else:
        return {"status": "success", "message": "Phone number is available."}


@frappe.whitelist()
@check_subscription_feature("phone_verification")
def send_phone_verification_code(phone: str):
    """
    Generate and send a phone verification code (OTP).
    This is used for both initial verification and resending.
    """
    if not phone:
        frappe.throw("Phone number is a required parameter.")

    # Generate a 6-digit OTP
    otp = "".join([str(random.randint(0, 9)) for _ in range(6)])

    # Store the OTP in cache for 10 minutes (600 seconds)
    cache_key = f"phone_otp:{phone}"
    frappe.cache().set_value(cache_key, otp, expires_in_sec=600)

    # Send SMS
    try:
        frappe.send_sms(
            receivers=[phone],
            message=f"Your verification code is: {otp}"
        )
    except Exception as e:
        frappe.log_error(f"Failed to send OTP SMS to {phone}: {e}", "SMS Sending Error")
        frappe.throw("Failed to send verification code. Please try again later.")

    return {"status": "success", "message": "Verification code sent successfully."}


@frappe.whitelist()
@check_subscription_feature("phone_verification")
def verify_phone_code(phone: str, otp: str):
    """
    Verify the OTP sent to a user's phone.
    Note: This flow is designed for existing users verifying their number.
    For new user registration, the OTP should be verified before the User doc is created.
    """
    if not phone or not otp:
        frappe.throw("Phone number and OTP are required parameters.")

    cache_key = f"phone_otp:{phone}"
    cached_otp = frappe.cache().get_value(cache_key)

    if not cached_otp:
        return {"status": "error", "message": "OTP expired or was not sent. Please request a new one."}

    if otp != cached_otp:
        return {"status": "error", "message": "Invalid verification code."}

    # OTP is correct, find user and mark as verified
    try:
        user = frappe.get_doc("User", {"phone": phone})
        user.phone_verified_at = frappe.utils.now_datetime()
        user.save(ignore_permissions=True)
    except frappe.DoesNotExistError:
        return {"status": "error", "message": "User with this phone number not found."}
    except Exception as e:
        frappe.log_error(f"Failed to update phone_verified_at for user with phone {phone}: {e}", "Phone Verification Error")
        frappe.throw("An error occurred while verifying your phone number. Please try again.")

    # Clear the OTP from cache
    frappe.cache().delete_value(cache_key)

    return {"status": "success", "message": "Phone number verified successfully."}


@frappe.whitelist(allow_guest=True)
def api_status():
    """
    Returns a simple status of the API.
    """
    return {
        "status": "ok",
        "version": frappe.get_attr("frappe.__version__"),
        "user": frappe.session.user
    }


@frappe.whitelist(allow_guest=True)
def register_user(email, password, first_name, last_name, phone=None):
    """
    Register a new user and send a verification email.
    """
    if frappe.db.exists("User", email):
        return {"status": "error", "message": "Email address already registered."}

    # Create the new user
    user = frappe.get_doc({
        "doctype": "User",
        "email": email,
        "first_name": first_name,
        "last_name": last_name,
        "phone": phone,
        "send_welcome_email": 0,
    })
    user.set("new_password", password)

    # Generate and store verification token
    token = frappe.generate_hash(length=48)
    user.email_verification_token = token
    user.insert(ignore_permissions=True)

    # Send the verification email
    verification_url = frappe.utils.get_url_to_method(
        "rokct.rokct.tenant.api.verify_my_email", {"token": token}
    )
    email_context = {
        "first_name": user.first_name,
        "verification_url": verification_url
    }
    frappe.sendmail(
        recipients=[user.email],
        template="New User Welcome",
        args=email_context,
        now=True
    )
    return {"status": "success", "message": "User registered successfully. Please check your email to verify your account."}


@frappe.whitelist(allow_guest=True)
def forgot_password(user: str):
    """
    Wrapper for Frappe's built-in reset_password method.
    `user` can be the user's email address.
    """
    try:
        frappe.core.doctype.user.user.reset_password(user=user)
        # Don't reveal if the user exists or not, always return success
        return {"status": "success", "message": "If a user with this email exists, a password reset link has been sent."}
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Forgot Password Error")
        # For security, still return a generic success message to the user
        return {"status": "success", "message": "If a user with this email exists, a password reset link has been sent."}


@frappe.whitelist(allow_guest=True)
def get_languages():
    """
    Returns a list of all enabled languages.
    """
    return frappe.get_all(
        "Language",
        filters={"enabled": 1},
        fields=["name", "language_name"]
    )


@frappe.whitelist(allow_guest=True)
def get_currencies():
    """
    Returns a list of all enabled currencies.
    """
    return frappe.get_all(
        "Currency",
        filters={"enabled": 1},
        fields=["name", "currency_name", "symbol"]
    )


@frappe.whitelist(allow_guest=True)
def check_coupon(code: str, shop_id: str, qty: int = 1):
    """
    Checks if a coupon is valid for a given shop.
    """
    if not code or not shop_id:
        frappe.throw("Code and shop ID are required.")

    coupon = frappe.db.get_value(
        "Coupon",
        filters={"code": code, "shop": shop_id},
        fieldname=["name", "expired_at", "quantity"],
        as_dict=True
    )

    if not coupon:
        return {"status": "error", "message": "Invalid Coupon"}

    if coupon.get("expired_at") and coupon.get("expired_at") < frappe.utils.now_datetime():
        return {"status": "error", "message": "Coupon expired"}

    if coupon.get("quantity") is not None and coupon.get("quantity") < qty:
        return {"status": "error", "message": "Coupon has been fully used"}

    # Check if the user has already used this coupon
    if frappe.session.user != "Guest" and frappe.db.exists("Coupon Usage", {"user": frappe.session.user, "coupon": coupon.name}):
        return {"status": "error", "message": "You have already used this coupon."}

    return frappe.get_doc("Coupon", coupon.name).as_dict()


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


# --- Shopping Cart APIs ---

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


# --- Receipt APIs ---

@frappe.whitelist(allow_guest=True)
def get_receipts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of receipts, formatted for frontend compatibility.
    """
    receipts = frappe.get_list(
        "Receipt",
        fields=["*"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

    # This is a simplified representation. A full implementation would
    # need to replicate the complex price calculation and relationship loading
    # from the original Laravel RestReceiptResource.

    return receipts


@frappe.whitelist(allow_guest=True)
def get_receipt(id: str):
    """
    Retrieves a single receipt.
    """
    receipt = frappe.get_doc("Receipt", id)

    # Again, this is a simplified representation.
    return receipt.as_dict()


# --- Blog APIs ---

@frappe.whitelist(allow_guest=True)
def get_blogs(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of published blog posts, formatted for frontend compatibility.
    """
    blog_posts = frappe.get_list(
        "Blog Post",
        filters={"published": 1},
        fields=["name", "title", "blogger", "blog_category", "published_on", "cover_image", "content"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="published_on desc"
    )

    # In a real scenario, you might want to fetch full user docs for the author
    # For now, we just get the name.

    formatted_blogs = []
    for post in blog_posts:
        formatted_blogs.append({
            "id": post.name,
            "uuid": post.name,
            "type": post.blog_category,
            "published_at": post.published_on,
            "active": True,
            "img": post.cover_image,
            "translation": {
                "title": post.title,
                "description": post.content,
            },
            "author": {
                "firstname": post.blogger,
            }
        })

    return formatted_blogs


@frappe.whitelist(allow_guest=True)
def get_blog(uuid: str):
    """
    Retrieves a single blog post by its UUID (name).
    """
    post = frappe.get_doc("Blog Post", uuid)
    if not post.published:
        frappe.throw("Blog post not published.", frappe.PermissionError)

    return {
        "id": post.name,
        "uuid": post.name,
        "type": post.blog_category,
        "published_at": post.published_on,
        "active": True,
        "img": post.cover_image,
        "translation": {
            "title": post.title,
            "description": post.content,
        },
        "author": {
            "firstname": post.blogger,
        }
    }


# --- Career APIs ---

@frappe.whitelist(allow_guest=True)
def get_careers(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of active careers, formatted for frontend compatibility.
    """
    careers = frappe.get_list(
        "Career",
        filters={"is_active": 1},
        fields=["name", "title", "description", "location", "category"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

    formatted_careers = []
    for career in careers:
        # The original response has a nested translation object.
        # We will simulate this structure.
        formatted_careers.append({
            "id": career.name,
            "location": career.location,
            "active": True,
            "category": {"name": career.category},
            "translation": {
                "title": career.title,
                "description": career.description
            }
        })

    return formatted_careers


@frappe.whitelist(allow_guest=True)
def get_career(id: str):
    """
    Retrieves a single career by its ID (name).
    """
    career = frappe.get_doc("Career", id)
    if not career.is_active:
        frappe.throw("Career not active.", frappe.PermissionError)

    return {
        "id": career.name,
        "location": career.location,
        "active": True,
        "category": {"name": career.category},
        "translation": {
            "title": career.title,
            "description": career.description
        }
    }


# --- Page APIs ---

@frappe.whitelist(allow_guest=True)
def get_page(route: str):
    """
    Retrieves a single web page by its route.
    """
    page = frappe.get_doc("Web Page", {"route": route})
    if not page.published:
        frappe.throw("Page not published.", frappe.PermissionError)

    # The original response has a nested translation object.
    # We will simulate this structure.
    return {
        "id": page.name,
        "type": page.route,
        "img": page.image,
        "active": page.published,
        "translation": {
            "title": page.title,
            "description": page.main_section,
        }
    }


# --- Delivery Zone APIs ---

def is_point_in_polygon(point, polygon):
    """
    Checks if a point is inside a polygon using the Ray-Casting algorithm.
    `point` should be a dict with 'latitude' and 'longitude'.
    `polygon` should be a list of dicts, each with 'latitude' and 'longitude'.
    """
    x, y = point['latitude'], point['longitude']
    n = len(polygon)
    inside = False

    p1x, p1y = polygon[0]['latitude'], polygon[0]['longitude']
    for i in range(n + 1):
        p2x, p2y = polygon[i % n]['latitude'], polygon[i % n]['longitude']
        if y > min(p1y, p2y):
            if y <= max(p1y, p2y):
                if x <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y

    return inside

@frappe.whitelist(allow_guest=True)
def get_delivery_zone_by_shop(shop_id: str):
    """
    Retrieves the delivery zone for a given shop.
    """
    if not frappe.db.exists("Company", shop_id):
        frappe.throw("Shop not found.")

    delivery_zone = frappe.get_doc("Delivery Zone", {"shop": shop_id})
    return delivery_zone.as_dict()


@frappe.whitelist(allow_guest=True)
def check_delivery_zone(shop_id: str, latitude: float, longitude: float):
    """
    Checks if a given coordinate is within the delivery zone of a shop.
    """
    if not frappe.db.exists("Company", shop_id):
        frappe.throw("Shop not found.")

    delivery_zone = frappe.get_doc("Delivery Zone", {"shop": shop_id})
    polygon = delivery_zone.get("coordinates")
    point = {"latitude": latitude, "longitude": longitude}

    if is_point_in_polygon(point, polygon):
        return {"status": "success", "message": "Address is within the delivery zone."}
    else:
        return {"status": "error", "message": "Address is outside the delivery zone."}


# --- Order Status APIs ---

@frappe.whitelist(allow_guest=True)
def get_order_statuses():
    """
    Retrieves a list of active order statuses, formatted for frontend compatibility.
    """
    statuses = frappe.get_list(
        "Order Status",
        filters={"is_active": 1},
        fields=["name", "status_name", "sort_order"],
        order_by="sort_order asc"
    )

    formatted_statuses = []
    for status in statuses:
        formatted_statuses.append({
            "id": status.name,
            "name": status.status_name,
            "active": True,
            "sort": status.sort_order,
        })

    return formatted_statuses


# --- Product History APIs ---

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


@frappe.whitelist(allow_guest=True)
def create_order(order_data):
    """
    Creates a new order.
    """
    if isinstance(order_data, str):
        order_data = json.loads(order_data)

    order = frappe.get_doc({
        "doctype": "Order",
        "user": order_data.get("user"),
        "shop": order_data.get("shop"),
        "status": "New",
        "delivery_type": order_data.get("delivery_type"),
        "currency": order_data.get("currency"),
        "rate": order_data.get("rate"),
        "delivery_fee": order_data.get("delivery_fee"),
        "waiter_fee": order_data.get("waiter_fee"),
        "tax": order_data.get("tax"),
        "commission_fee": order_data.get("commission_fee"),
        "service_fee": order_data.get("service_fee"),
        "total_discount": order_data.get("total_discount"),
        "coupon_code": order_data.get("coupon_code"),
        "location": order_data.get("location"),
        "address": order_data.get("address"),
        "phone": order_data.get("phone"),
        "username": order_data.get("username"),
        "delivery_date": order_data.get("delivery_date"),
        "delivery_time": order_data.get("delivery_time"),
        "note": order_data.get("note"),
    })

    for item in order_data.get("order_items", []):
        order.append("order_items", {
            "product": item.get("product"),
            "quantity": item.get("quantity"),
            "price": item.get("price"),
        })

    order.insert(ignore_permissions=True)

    if order_data.get("coupon_code"):
        coupon = frappe.get_doc("Coupon", {"code": order_data.get("coupon_code")})
        frappe.get_doc({
            "doctype": "Coupon Usage",
            "coupon": coupon.name,
            "user": order.user,
            "order": order.name
        }).insert(ignore_permissions=True)

    return order.as_dict()


@frappe.whitelist()
def list_orders(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of orders for the current user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.")

    orders = frappe.get_list(
        "Order",
        filters={"user": user},
        fields=["name", "shop", "total_price", "status", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_order_details(order_id: str):
    """
    Retrieves the details of a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.")

    order = frappe.get_doc("Order", order_id)
    if order.user != user:
        frappe.throw("You are not authorized to view this order.", frappe.PermissionError)
    return order.as_dict()


@frappe.whitelist()
def update_order_status(order_id: str, status: str):
    """
    Updates the status of a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update an order.")

    order = frappe.get_doc("Order", order_id)

    if order.user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw("You are not authorized to update this order.", frappe.PermissionError)

    valid_statuses = frappe.get_meta("Order").get_field("status").options.split("\n")
    if status not in valid_statuses:
        frappe.throw(f"Invalid status. Must be one of {', '.join(valid_statuses)}")

    order.status = status
    order.save(ignore_permissions=True)
    return order.as_dict()


@frappe.whitelist()
def add_order_review(order_id: str, rating: float, comment: str = None):
    """
    Adds a review for a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to leave a review.")

    order = frappe.get_doc("Order", order_id)

    if order.user != user:
        frappe.throw("You can only review your own orders.", frappe.PermissionError)

    if order.status != "Delivered":
        frappe.throw("You can only review delivered orders.")

    if frappe.db.exists("Review", {"reviewable_type": "Order", "reviewable_id": order_id, "user": user}):
        frappe.throw("You have already reviewed this order.")

    review = frappe.get_doc({
        "doctype": "Review",
        "reviewable_type": "Order",
        "reviewable_id": order_id,
        "user": user,
        "rating": rating,
        "comment": comment,
        "published": 1
    })
    review.insert(ignore_permissions=True)
    return review.as_dict()


@frappe.whitelist()
def cancel_order(order_id: str):
    """
    Cancels a specific order.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to cancel an order.")

    order = frappe.get_doc("Order", order_id)

    if order.user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw("You are not authorized to cancel this order.", frappe.PermissionError)

    if order.status != "New":
        frappe.throw("You can only cancel orders that have not been accepted yet.")

    order.status = "Cancelled"

    # Replenish stock by creating a Stock Entry for stock reconciliation
    stock_entry = frappe.get_doc({
        "doctype": "Stock Entry",
        "purpose": "Stock Reconciliation",
        "items": []
    })
    for item in order.order_items:
        stock_entry.append("items", {
            "item_code": item.product,
            "qty": item.quantity,
            "s_warehouse": "Stores", # Or get from product/order
            "t_warehouse": "Stores", # Or get from product/order
            "diff_qty": item.quantity,
            "basic_rate": item.price
        })
    stock_entry.insert(ignore_permissions=True)
    stock_entry.submit()

    order.save(ignore_permissions=True)
    return order.as_dict()


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


# --- Branch APIs ---

@frappe.whitelist(allow_guest=True)
def get_branches(shop_id: str):
    """
    Retrieves a list of branches for a given shop.
    """
    if not frappe.db.exists("Company", shop_id):
        frappe.throw("Shop not found.")

    branches = frappe.get_list(
        "Branch",
        filters={"shop": shop_id},
        fields=["name", "address", "latitude", "longitude"]
    )
    return branches


@frappe.whitelist(allow_guest=True)
def get_branch(branch_id: str):
    """
    Retrieves a single branch.
    """
    return frappe.get_doc("Branch", branch_id).as_dict()


@frappe.whitelist()
def create_branch(branch_data):
    """
    Creates a new branch.
    """
    if isinstance(branch_data, str):
        branch_data = json.loads(branch_data)

    branch = frappe.get_doc({
        "doctype": "Branch",
        "branch_name": branch_data.get("name"),
        "address": branch_data.get("address"),
        "latitude": branch_data.get("latitude"),
        "longitude": branch_data.get("longitude"),
        "shop": branch_data.get("shop"),
        "owner": frappe.session.user
    })
    branch.insert(ignore_permissions=True)
    return branch.as_dict()


@frappe.whitelist()
def update_branch(branch_id, branch_data):
    """
    Updates an existing branch.
    """
    if isinstance(branch_data, str):
        branch_data = json.loads(branch_data)

    branch = frappe.get_doc("Branch", branch_id)
    if branch.owner != frappe.session.user and "System Manager" not in frappe.get_roles(frappe.session.user):
        frappe.throw("You are not authorized to update this branch.", frappe.PermissionError)

    branch.branch_name = branch_data.get("name", branch.branch_name)
    branch.address = branch_data.get("address", branch.address)
    branch.latitude = branch_data.get("latitude", branch.latitude)
    branch.longitude = branch_data.get("longitude", branch.longitude)
    branch.shop = branch_data.get("shop", branch.shop)
    branch.save(ignore_permissions=True)
    return branch.as_dict()


@frappe.whitelist()
def delete_branch(branch_id):
    """
    Deletes a branch.
    """
    branch = frappe.get_doc("Branch", branch_id)
    if branch.owner != frappe.session.user and "System Manager" not in frappe.get_roles(frappe.session.user):
        frappe.throw("You are not authorized to delete this branch.", frappe.PermissionError)

    frappe.delete_doc("Branch", branch_id, ignore_permissions=True)
    return {"status": "success", "message": "Branch deleted successfully."}
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
def get_delivery_points():
    """
    Retrieves a list of all active delivery points.
    """
    delivery_points = frappe.get_list(
        "Delivery Point",
        filters={"active": 1},
        fields=["name", "price", "address", "location", "img"]
    )
    return delivery_points


@frappe.whitelist(allow_guest=True)
def get_delivery_point(name):
    """
    Retrieves a single delivery point by its name.
    """
    return frappe.get_doc("Delivery Point", name).as_dict()


@frappe.whitelist()
def get_user_membership():
    """
    Retrieves the active membership for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your membership.", frappe.AuthenticationError)

    user_membership = frappe.get_all(
        "User Membership",
        filters={"user": user, "is_active": 1},
        fields=["name", "membership", "start_date", "end_date"],
        order_by="end_date desc",
        limit=1
    )

    if not user_membership:
        return None

    return user_membership[0]

@frappe.whitelist()
def get_user_membership_history():
    """
    Retrieves the membership history for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your membership history.", frappe.AuthenticationError)

    return frappe.get_all(
        "User Membership",
        filters={"user": user},
        fields=["name", "membership", "start_date", "end_date", "is_active"],
        order_by="end_date desc"
    )


@frappe.whitelist()
def create_parcel_order(order_data):
    """
    Creates a new parcel order.
    """
    if isinstance(order_data, str):
        order_data = json.loads(order_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to create a parcel order.", frappe.AuthenticationError)

    parcel_order = frappe.get_doc({
        "doctype": "Parcel Order",
        "user": user,
        "total_price": order_data.get("total_price"),
        "currency": order_data.get("currency"),
        "type": order_data.get("type"),
        "note": order_data.get("note"),
        "tax": order_data.get("tax"),
        "status": "New",
        "address_from": json.dumps(order_data.get("address_from")),
        "phone_from": order_data.get("phone_from"),
        "username_from": order_data.get("username_from"),
        "address_to": json.dumps(order_data.get("address_to")),
        "phone_to": order_data.get("phone_to"),
        "username_to": order_data.get("username_to"),
        "delivery_fee": order_data.get("delivery_fee"),
        "delivery_date": order_data.get("delivery_date"),
        "delivery_time": order_data.get("delivery_time"),
    })
    parcel_order.insert(ignore_permissions=True)
    return parcel_order.as_dict()

@frappe.whitelist()
def get_user_parcel_orders():
    """
    Retrieves the parcel order history for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your parcel orders.", frappe.AuthenticationError)

    return frappe.get_all(
        "Parcel Order",
        filters={"user": user},
        fields=["name", "status", "total_price", "delivery_date"],
        order_by="creation desc"
    )

@frappe.whitelist()
def get_user_parcel_order(name):
    """
    Retrieves a single parcel order for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your parcel orders.", frappe.AuthenticationError)

    parcel_order = frappe.get_doc("Parcel Order", name)
    if parcel_order.user != user:
        frappe.throw("You are not authorized to view this parcel order.", frappe.PermissionError)

    return parcel_order.as_dict()


@frappe.whitelist()
def get_user_addresses():
    """
    Retrieves the list of addresses for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your addresses.", frappe.AuthenticationError)

    return frappe.get_all(
        "User Address",
        filters={"user": user},
        fields=["name", "title", "address", "location", "active"]
    )

@frappe.whitelist()
def get_user_address(name):
    """
    Retrieves a single address for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your addresses.", frappe.AuthenticationError)

    address = frappe.get_doc("User Address", name)
    if address.user != user:
        frappe.throw("You are not authorized to view this address.", frappe.PermissionError)

    return address.as_dict()

@frappe.whitelist()
def add_user_address(address_data):
    """
    Adds a new address for the currently logged-in user.
    """
    if isinstance(address_data, str):
        address_data = json.loads(address_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to add an address.", frappe.AuthenticationError)

    address = frappe.get_doc({
        "doctype": "User Address",
        "user": user,
        "title": address_data.get("title"),
        "address": json.dumps(address_data.get("address")),
        "location": json.dumps(address_data.get("location")),
        "active": address_data.get("active", 1)
    })
    address.insert(ignore_permissions=True)
    return address.as_dict()

@frappe.whitelist()
def update_user_address(name, address_data):
    """
    Updates an existing address for the currently logged-in user.
    """
    if isinstance(address_data, str):
        address_data = json.loads(address_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update an address.", frappe.AuthenticationError)

    address = frappe.get_doc("User Address", name)
    if address.user != user:
        frappe.throw("You are not authorized to update this address.", frappe.PermissionError)

    address.title = address_data.get("title", address.title)
    address.address = json.dumps(address_data.get("address", address.address))
    address.location = json.dumps(address_data.get("location", address.location))
    address.active = address_data.get("active", address.active)
    address.save(ignore_permissions=True)
    return address.as_dict()

@frappe.whitelist()
def delete_user_address(name):
    """
    Deletes an address for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to delete an address.", frappe.AuthenticationError)

    address = frappe.get_doc("User Address", name)
    if address.user != user:
        frappe.throw("You are not authorized to delete this address.", frappe.PermissionError)

    frappe.delete_doc("User Address", name, ignore_permissions=True)
    return {"status": "success", "message": "Address deleted successfully."}


@frappe.whitelist()
def get_user_invites():
    """
    Retrieves the list of invites for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your invites.", frappe.AuthenticationError)

    return frappe.get_all(
        "Invitation",
        filters={"user": user},
        fields=["name", "shop", "role", "status"]
    )

@frappe.whitelist()
def create_invite(shop, user, role):
    """
    Creates a new invite.
    """
    # In a real application, we would have more permission checks here.
    # For example, only a shop owner or manager should be able to invite users.
    # For now, we will assume the user has the necessary permissions.

    invite = frappe.get_doc({
        "doctype": "Invitation",
        "shop": shop,
        "user": user,
        "role": role,
        "status": "New"
    })
    invite.insert(ignore_permissions=True)
    return invite.as_dict()

@frappe.whitelist()
def update_invite_status(name, status):
    """
    Updates the status of an invite.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update an invite.", frappe.AuthenticationError)

    invite = frappe.get_doc("Invitation", name)
    if invite.user != user:
        frappe.throw("You are not authorized to update this invite.", frappe.PermissionError)

    if status not in ["Accepted", "Rejected"]:
        frappe.throw("Invalid status. Must be 'Accepted' or 'Rejected'.")

    invite.status = status
    invite.save(ignore_permissions=True)
    return invite.as_dict()


@frappe.whitelist()
def get_user_wallet():
    """
    Retrieves the wallet for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your wallet.", frappe.AuthenticationError)

    wallet = frappe.get_doc("Wallet", {"user": user})
    return wallet.as_dict()

@frappe.whitelist()
def get_wallet_history(limit_start=0, limit_page_length=20):
    """
    Retrieves the wallet history for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your wallet history.", frappe.AuthenticationError)

    wallet = frappe.get_doc("Wallet", {"user": user})
    return frappe.get_all(
        "Wallet History",
        filters={"wallet": wallet.name},
        fields=["name", "type", "price", "status", "created_at"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def export_orders():
    """
    Exports all orders for the current user to a CSV file.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to export orders.", frappe.AuthenticationError)

    orders = frappe.get_all(
        "Order",
        filters={"user": user},
        fields=["name", "shop", "total_price", "status", "creation"],
        order_by="creation desc"
    )

    if not orders:
        return []

    # Create a CSV in memory
    output = io.StringIO()
    writer = csv.writer(output)

    # Write the header row
    writer.writerow(["Order ID", "Shop", "Total Price", "Status", "Date"])

    # Write the data rows
    for order in orders:
        writer.writerow([order.name, order.shop, order.total_price, order.status, order.creation])

    # Set the response headers for CSV download
    frappe.local.response.filename = "orders.csv"
    frappe.local.response.filecontent = output.getvalue()
    frappe.local.response.type = "csv"


@frappe.whitelist()
def register_device_token(device_token: str, provider: str):
    """
    Registers a new device token for the current user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to register a device token.", frappe.AuthenticationError)

    if not device_token or not provider:
        frappe.throw("Device token and provider are required.")

    if frappe.db.exists("Device Token", {"device_token": device_token}):
        return {"status": "success", "message": "Device token already registered."}

    frappe.get_doc({
        "doctype": "Device Token",
        "user": user,
        "device_token": device_token,
        "provider": provider
    }).insert(ignore_permissions=True)
    return {"status": "success", "message": "Device token registered successfully."}


@frappe.whitelist()
def send_push_notification(user: str, title: str, body: str):
    """
    Sends a push notification to a specific user.
    """
    # TODO: Implement the actual push notification logic using a third-party service like FCM or APNS.
    # This will require credentials and a library to interact with the service.
    # For now, we will just log the notification.
    frappe.log_error(f"Push notification for user {user}: {title} - {body}", "Push Notification")
    return {"status": "success", "message": "Push notification sent (logged)."}


@frappe.whitelist()
def get_deliveryman_orders(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of orders assigned to the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.", frappe.AuthenticationError)

    orders = frappe.get_list(
        "Order",
        filters={"deliveryman": user},
        fields=["name", "shop", "total_price", "status", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_deliveryman_parcel_orders(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of parcel orders assigned to the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your parcel orders.", frappe.AuthenticationError)

    orders = frappe.get_list(
        "Parcel Order",
        filters={"deliveryman": user},
        fields=["name", "status", "total_price", "delivery_date"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_deliveryman_settings():
    """
    Retrieves the settings for the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your settings.", frappe.AuthenticationError)

    if not frappe.db.exists("Deliveryman Settings", {"user": user}):
        return {}

    return frappe.get_doc("Deliveryman Settings", {"user": user}).as_dict()


@frappe.whitelist()
def update_deliveryman_settings(settings_data):
    """
    Updates the settings for the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update your settings.", frappe.AuthenticationError)

    if isinstance(settings_data, str):
        settings_data = json.loads(settings_data)

    if not frappe.db.exists("Deliveryman Settings", {"user": user}):
        settings = frappe.new_doc("Deliveryman Settings")
        settings.user = user
    else:
        settings = frappe.get_doc("Deliveryman Settings", {"user": user})

    settings.update(settings_data)
    settings.save(ignore_permissions=True)
    return settings.as_dict()


@frappe.whitelist()
def get_deliveryman_statistics():
    """
    Retrieves statistics for the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your statistics.", frappe.AuthenticationError)

    # Total completed orders
    completed_orders_count = frappe.db.count(
        "Order",
        filters={
            "deliveryman": user,
            "status": "Delivered"
        }
    )

    # Total completed parcel orders
    completed_parcel_orders_count = frappe.db.count(
        "Parcel Order",
        filters={
            "deliveryman": user,
            "status": "Delivered"
        }
    )

    # Total earnings from regular orders
    total_order_earnings = frappe.db.sql("""
        SELECT SUM(delivery_fee)
        FROM `tabOrder`
        WHERE deliveryman = %(user)s AND status = 'Delivered'
    """, {"user": user})[0][0] or 0

    # Total earnings from parcel orders
    total_parcel_earnings = frappe.db.sql("""
        SELECT SUM(delivery_fee)
        FROM `tabParcel Order`
        WHERE deliveryman = %(user)s AND status = 'Delivered'
    """, {"user": user})[0][0] or 0

    total_earnings = total_order_earnings + total_parcel_earnings

    return {
        "completed_orders": completed_orders_count,
        "completed_parcel_orders": completed_parcel_orders_count,
        "total_orders": completed_orders_count + completed_parcel_orders_count,
        "total_earnings": total_earnings
    }


@frappe.whitelist()
def get_banned_shops():
    """
    Retrieves a list of shops from which the current deliveryman is banned.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your banned shops.", frappe.AuthenticationError)

    banned_shops = frappe.get_all(
        "Shop Ban",
        filters={"deliveryman": user},
        fields=["shop"]
    )
    return [d.shop for d in banned_shops]


@frappe.whitelist()
def get_deliveryman_payouts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of payouts for the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your payouts.", frappe.AuthenticationError)

    payouts = frappe.get_list(
        "Payout",
        filters={"deliveryman": user},
        fields=["name", "amount", "payment_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payment_date desc"
    )
    return payouts


@frappe.whitelist()
def get_deliveryman_order_report(from_date: str, to_date: str):
    """
    Retrieves a report of orders and parcel orders for the current deliveryman within a date range.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your order report.", frappe.AuthenticationError)

    orders = frappe.get_all(
        "Order",
        filters={
            "deliveryman": user,
            "status": "Delivered",
            "creation": ["between", [from_date, to_date]]
        },
        fields=["name", "shop", "total_price", "status", "creation"],
        order_by="creation desc"
    )

    parcel_orders = frappe.get_all(
        "Parcel Order",
        filters={
            "deliveryman": user,
            "status": "Delivered",
            "creation": ["between", [from_date, to_date]]
        },
        fields=["name", "status", "total_price", "delivery_date"],
        order_by="creation desc"
    )

    return {
        "orders": orders,
        "parcel_orders": parcel_orders
    }


@frappe.whitelist()
def get_deliveryman_delivery_zones():
    """
    Retrieves a list of delivery zones assigned to the current deliveryman.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your delivery zones.", frappe.AuthenticationError)

    delivery_zones = frappe.get_all(
        "Deliveryman Delivery Zone",
        filters={"deliveryman": user},
        fields=["delivery_zone"]
    )
    return [d.delivery_zone for d in delivery_zones]


@frappe.whitelist()
def get_user_transactions(limit_start=0, limit_page_length=20):
    """
    Retrieve the list of transactions for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your transactions.", frappe.AuthenticationError)

    # The 'Transaction' doctype in Frappe links to a 'Party' which can be a customer.
    # We first need to get the customer associated with the user.
    customer = frappe.db.get_value("Customer", {"email": user}, "name")
    if not customer:
        return []

    return frappe.get_all(
        "Transaction",
        filters={"party": customer},
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "debit", "credit", "currency"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_user_shop():
    """
    Retrieves the shop owned by the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your shop.", frappe.AuthenticationError)

    # Assuming user_id is a custom field on Company, or we're using another linking mechanism
    try:
        shop_name = frappe.db.get_value("Company", {"user_id": user}, "name")
        if not shop_name:
            return None
        return frappe.get_doc("Company", shop_name).as_dict()
    except frappe.DoesNotExistError:
        return None

@frappe.whitelist()
def update_user_shop(shop_data):
    """
    Updates the shop owned by the currently logged-in user.
    """
    if isinstance(shop_data, str):
        shop_data = json.loads(shop_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update your shop.", frappe.AuthenticationError)

    shop_name = frappe.db.get_value("Company", {"user_id": user}, "name")
    if not shop_name:
        frappe.throw("You do not own a shop.", frappe.PermissionError)

    shop = frappe.get_doc("Company", shop_name)

    # List of fields that a user is allowed to update
    updatable_fields = ["phone", "location", "delivery_time", "open"]

    for key, value in shop_data.items():
        if key in updatable_fields:
            if key in ["location", "delivery_time"]:
                shop.set(key, json.dumps(value))
            else:
                shop.set(key, value)

    # Handle translations separately (simplified)
    if "title" in shop_data:
        shop.company_name = shop_data.get("title")
    if "description" in shop_data:
        # Assuming a custom field 'description' exists on Company
        shop.description = shop_data.get("description")

    shop.save(ignore_permissions=True)
    return shop.as_dict()


@frappe.whitelist()
def get_user_request_models(limit_start=0, limit_page_length=20):
    """
    Retrieves the list of request models for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your request models.", frappe.AuthenticationError)

    return frappe.get_all(
        "Request Model",
        filters={"created_by_user": user},
        fields=["name", "model_type", "model", "status", "created_at"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def create_request_model(model_type, model_id, data):
    """
    Creates a new request model.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to create a request model.", frappe.AuthenticationError)

    request_model = frappe.get_doc({
        "doctype": "Request Model",
        "model_type": model_type,
        "model": model_id,
        "data": json.dumps(data),
        "created_by_user": user,
        "status": "Pending"
    })
    request_model.insert(ignore_permissions=True)
    return request_model.as_dict()


@frappe.whitelist()
def get_user_tickets(limit_start=0, limit_page_length=20):
    """
    Retrieves the list of tickets for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your tickets.", frappe.AuthenticationError)

    return frappe.get_all(
        "Ticket",
        filters={"created_by_user": user, "parent_ticket": None}, # Only get parent tickets
        fields=["name", "subject", "status", "creation"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def get_user_ticket(name):
    """
    Retrieves a single ticket and its replies for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your tickets.", frappe.AuthenticationError)

    ticket = frappe.get_doc("Ticket", name)
    if ticket.created_by_user != user:
        frappe.throw("You are not authorized to view this ticket.", frappe.PermissionError)

    replies = frappe.get_all(
        "Ticket",
        filters={"parent_ticket": name},
        fields=["name", "content", "created_by_user", "creation"]
    )

    ticket_dict = ticket.as_dict()
    ticket_dict["replies"] = replies
    return ticket_dict

@frappe.whitelist()
def create_ticket(subject, content, order_id=None):
    """
    Creates a new ticket.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to create a ticket.", frappe.AuthenticationError)

    ticket = frappe.get_doc({
        "doctype": "Ticket",
        "uuid": str(uuid.uuid4()),
        "subject": subject,
        "content": content,
        "order": order_id,
        "created_by_user": user,
        "user": user,
        "status": "Open",
        "type": "order" if order_id else "general"
    })
    ticket.insert(ignore_permissions=True)
    return ticket.as_dict()

@frappe.whitelist()
def reply_to_ticket(name, content):
    """
    Adds a reply to an existing ticket.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to reply to a ticket.", frappe.AuthenticationError)

    parent_ticket = frappe.get_doc("Ticket", name)
    if parent_ticket.created_by_user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw("You are not authorized to reply to this ticket.", frappe.PermissionError)

    reply = frappe.get_doc({
        "doctype": "Ticket",
        "uuid": str(uuid.uuid4()),
        "parent_ticket": name,
        "subject": f"Re: {parent_ticket.subject}",
        "content": content,
        "created_by_user": user,
        "user": user,
        "status": "Answered"
    })
    reply.insert(ignore_permissions=True)

    # Update parent ticket status
    parent_ticket.status = "Answered"
    parent_ticket.save(ignore_permissions=True)

    return reply.as_dict()


@frappe.whitelist()
def get_user_profile():
    """
    Retrieves the profile information for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your profile.", frappe.AuthenticationError)

    user_doc = frappe.get_doc("User", user)

    return {
        "first_name": user_doc.first_name,
        "last_name": user_doc.last_name,
        "email": user_doc.email,
        "phone": user_doc.phone,
        "birth_date": user_doc.birth_date,
        "location": user_doc.location,
        "gender": user_doc.gender,
    }


@frappe.whitelist()
def update_user_profile(profile_data):
    """
    Updates the profile information for the currently logged-in user.
    """
    if isinstance(profile_data, str):
        profile_data = json.loads(profile_data)

    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update your profile.", frappe.AuthenticationError)

    user_doc = frappe.get_doc("User", user)

    # List of fields that a user is allowed to update
    updatable_fields = ["first_name", "last_name", "phone", "birth_date", "location", "gender"]

    for key, value in profile_data.items():
        if key in updatable_fields:
            user_doc.set(key, value)

    user_doc.save(ignore_permissions=True)

    return {"status": "success", "message": "Profile updated successfully."}


@frappe.whitelist()
def get_user_order_refunds(limit_start=0, limit_page_length=20):
    """
    Retrieves the list of order refunds for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your order refunds.", frappe.AuthenticationError)

    # Get all orders for the user
    user_orders = frappe.get_all("Order", filters={"user": user}, pluck="name")

    if not user_orders:
        return []

    return frappe.get_all(
        "Order Refund",
        filters={"order": ["in", user_orders]},
        fields=["name", "order", "status", "cause", "answer"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def create_order_refund(order, cause):
    """
    Creates a new order refund request.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to request a refund.", frappe.AuthenticationError)

    # Check if the user owns the order
    order_doc = frappe.get_doc("Order", order)
    if order_doc.user != user:
        frappe.throw("You are not authorized to request a refund for this order.", frappe.PermissionError)

    refund = frappe.get_doc({
        "doctype": "Order Refund",
        "order": order,
        "cause": cause,
        "status": "Pending"
    })
    refund.insert(ignore_permissions=True)
    return refund.as_dict()


@frappe.whitelist()
def get_user_notifications(limit_start=0, limit_page_length=20):
    """
    Retrieves the list of notifications for the currently logged-in user.
    """
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your notifications.", frappe.AuthenticationError)

    # The Notification doctype in Frappe is complex.
    # It is used for email alerts and other system notifications.
    # A simple way to get user-specific notifications is to look at the
    # Notification Log, which records when a notification is sent to a user.

    return frappe.get_all(
        "Notification Log",
        filters={"for_user": user},
        fields=["name", "subject", "document_type", "document_name", "creation"],
        order_by="creation desc",
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


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

@frappe.whitelist()
def get_categories(limit_start: int = 0, limit_page_length: int = 10, order_by: str = "name", order: str = "desc", parent: bool = False, select: bool = False, **kwargs):
    """
    Retrieves a list of categories with pagination and filters.
    """
    filters = {}
    if parent:
        filters["parent_category"] = ""

    if kwargs.get("type"):
        filters["type"] = kwargs.get("type")

    if kwargs.get("shop_id"):
        filters["shop"] = kwargs.get("shop_id")

    if kwargs.get("active"):
        filters["active"] = int(kwargs.get("active"))

    fields = ["name", "uuid", "type", "image", "active", "status", "shop"]
    if select:
        fields = ["name", "uuid"]

    categories = frappe.get_list(
        "Category",
        fields=fields,
        filters=filters,
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by=f"{order_by} {order}"
    )

    return categories


@frappe.whitelist(allow_guest=True)
def get_category_types():
    """
    Returns a list of all available category types.
    """
    category_meta = frappe.get_meta("Category")
    type_field = category_meta.get_field("type")
    return type_field.options.split("\n")




@frappe.whitelist()
def get_children_categories(id: str, limit_start: int = 0, limit_page_length: int = 10):
    """
    Retrieves the children of a given category.
    """
    categories = frappe.get_list(
        "Category",
        fields=["name", "uuid", "type", "image", "active", "status", "shop"],
        filters={"parent_category": id},
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name desc"
    )

    return categories


@frappe.whitelist()
def search_categories(search: str, limit_start: int = 0, limit_page_length: int = 10):
    """
    Searches for categories by a search term.
    """
    categories = frappe.get_list(
        "Category",
        fields=["name", "uuid", "type", "image", "active", "status", "shop"],
        filters=[
            ["Category", "keywords", "like", f"%{search}%"],
        ],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name desc"
    )

    return categories


@frappe.whitelist()
def get_category_by_uuid(uuid: str):
    """
    Retrieves a single category by its UUID.
    """
    category = frappe.get_doc("Category", {"uuid": uuid})
    return category.as_dict()


@frappe.whitelist()
def create_category(category_data):
    """
    Creates a new category.
    """
    if isinstance(category_data, str):
        category_data = json.loads(category_data)

    category_uuid = category_data.get("uuid") or str(uuid.uuid4())

    if not category_data.get("type"):
        frappe.throw("Category type is required.")

    if frappe.db.exists("Category", {"uuid": category_uuid}):
        frappe.throw("Category with this UUID already exists.")

    category = frappe.get_doc({
        "doctype": "Category",
        "uuid": category_uuid,
        "slug": category_data.get("slug"),
        "keywords": category_data.get("keywords"),
        "parent_category": category_data.get("parent_category"),
        "type": category_data.get("type"),
        "image": category_data.get("image"),
        "active": category_data.get("active", 1),
        "status": category_data.get("status", "pending"),
        "shop": category_data.get("shop"),
        "input": category_data.get("input"),
    })
    category.insert(ignore_permissions=True)
    return category.as_dict()


@frappe.whitelist()
def update_category(uuid, category_data):
    """
    Updates an existing category by its UUID.
    """
    if not uuid:
        frappe.throw("UUID is required to update a category.")

    if isinstance(category_data, str):
        category_data = json.loads(category_data)

    category_name = frappe.db.get_value("Category", {"uuid": uuid}, "name")
    if not category_name:
        frappe.throw("Category not found.")

    category = frappe.get_doc("Category", category_name)

    updatable_fields = ["slug", "keywords", "parent_category", "type", "image", "active", "status", "shop", "input"]

    for key, value in category_data.items():
        if key in updatable_fields:
            category.set(key, value)

    category.save(ignore_permissions=True)
    return category.as_dict()


@frappe.whitelist()
def delete_category(uuid):
    """
    Deletes a category by its UUID.
    """
    if not uuid:
        frappe.throw("UUID is required to delete a category.")

    category_name = frappe.db.get_value("Category", {"uuid": uuid}, "name")
    if not category_name:
        frappe.throw("Category not found.")

    frappe.delete_doc("Category", category_name, ignore_permissions=True)

    return {"status": "success", "message": "Category deleted successfully."}


@frappe.whitelist()
def get_brands(limit_start: int = 0, limit_page_length: int = 10):
    """
    Retrieves a list of brands.
    """
    brands = frappe.get_list(
        "Brand",
        fields=["name", "uuid", "title", "slug", "active", "image", "shop"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="name desc"
    )
    return brands


@frappe.whitelist()
def get_brand_by_uuid(uuid: str):
    """
    Retrieves a single brand by its UUID.
    """
    brand = frappe.get_doc("Brand", {"uuid": uuid})
    return brand.as_dict()


@frappe.whitelist()
def create_brand(brand_data):
    """
    Creates a new brand.
    """
    if isinstance(brand_data, str):
        brand_data = json.loads(brand_data)

    brand_uuid = brand_data.get("uuid") or str(uuid.uuid4())

    if not brand_data.get("title"):
        frappe.throw("Brand title is required.")

    if frappe.db.exists("Brand", {"uuid": brand_uuid}):
        frappe.throw("Brand with this UUID already exists.")

    brand = frappe.get_doc({
        "doctype": "Brand",
        "uuid": brand_uuid,
        "title": brand_data.get("title"),
        "slug": brand_data.get("slug"),
        "active": brand_data.get("active", 1),
        "image": brand_data.get("image"),
        "shop": brand_data.get("shop"),
    })
    brand.insert(ignore_permissions=True)
    return brand.as_dict()


@frappe.whitelist()
def update_brand(uuid, brand_data):
    """
    Updates an existing brand by its UUID.
    """
    if not uuid:
        frappe.throw("UUID is required to update a brand.")

    if isinstance(brand_data, str):
        brand_data = json.loads(brand_data)

    brand_name = frappe.db.get_value("Brand", {"uuid": uuid}, "name")
    if not brand_name:
        frappe.throw("Brand not found.")

    brand = frappe.get_doc("Brand", brand_name)

    updatable_fields = ["title", "slug", "active", "image", "shop"]

    for key, value in brand_data.items():
        if key in updatable_fields:
            brand.set(key, value)

    brand.save(ignore_permissions=True)
    return brand.as_dict()


@frappe.whitelist()
def delete_brand(uuid):
    """
    Deletes a brand by its UUID.
    """
    if not uuid:
        frappe.throw("UUID is required to delete a brand.")

    brand_name = frappe.db.get_value("Brand", {"uuid": uuid}, "name")
    if not brand_name:
        frappe.throw("Brand not found.")

    frappe.delete_doc("Brand", brand_name, ignore_permissions=True)

    return {"status": "success", "message": "Brand deleted successfully."}