import frappe
import json
from ..seller.utils import _get_seller_shop
from rokct.rokct.tenant.api import get_subscription_details

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