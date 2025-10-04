import frappe
import json

def _require_admin():
    """Helper function to ensure the user has the System Manager role."""
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", frappe.PermissionError)

@frappe.whitelist()
def get_admin_statistics():
    """
    Retrieves high-level statistics for the admin dashboard.
    """
    _require_admin()

    total_users = frappe.db.count("User")
    total_shops = frappe.db.count("Company")
    total_orders = frappe.db.count("Order")
    total_sales = frappe.db.sql("SELECT SUM(grand_total) FROM `tabOrder` WHERE status = 'Delivered'")[0][0] or 0

    return {
        "total_users": total_users,
        "total_shops": total_shops,
        "total_orders": total_orders,
        "total_sales": total_sales,
    }


@frappe.whitelist()
def get_all_shops(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shops on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Company",
        fields=["name", "company_name", "user_id"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_shop(shop_data):
    """
    Creates a new shop (for admins).
    """
    _require_admin()
    if isinstance(shop_data, str):
        shop_data = json.loads(shop_data)

    new_shop = frappe.get_doc({
        "doctype": "Company",
        **shop_data
    })
    new_shop.insert(ignore_permissions=True)
    return new_shop.as_dict()


@frappe.whitelist()
def update_shop(shop_name, shop_data):
    """
    Updates a shop (for admins).
    """
    _require_admin()
    if isinstance(shop_data, str):
        shop_data = json.loads(shop_data)

    shop = frappe.get_doc("Company", shop_name)
    shop.update(shop_data)
    shop.save(ignore_permissions=True)
    return shop.as_dict()


@frappe.whitelist()
def delete_shop(shop_name):
    """
    Deletes a shop (for admins).
    """
    _require_admin()
    frappe.delete_doc("Company", shop_name, ignore_permissions=True)
    return {"status": "success", "message": "Shop deleted successfully."}


@frappe.whitelist()
def get_all_users(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all users on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "User",
        fields=["name", "full_name", "email", "enabled"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def get_admin_stories(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all stories on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Story",
        fields=["name", "title", "shop", "expires_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def get_admin_banners(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of platform-wide banners (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Banner",
        filters={"shop": None},
        fields=["name", "title", "image", "link", "is_active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_admin_banner(banner_data):
    """
    Creates a new platform-wide banner (for admins).
    """
    _require_admin()
    if isinstance(banner_data, str):
        banner_data = json.loads(banner_data)

    banner_data["shop"] = None

    new_banner = frappe.get_doc({
        "doctype": "Banner",
        **banner_data
    })
    new_banner.insert(ignore_permissions=True)
    return new_banner.as_dict()


@frappe.whitelist()
def update_admin_banner(banner_name, banner_data):
    """
    Updates a platform-wide banner (for admins).
    """
    _require_admin()
    if isinstance(banner_data, str):
        banner_data = json.loads(banner_data)

    banner = frappe.get_doc("Banner", banner_name)
    banner.update(banner_data)
    banner.save(ignore_permissions=True)
    return banner.as_dict()


@frappe.whitelist()
def delete_admin_banner(banner_name):
    """
    Deletes a platform-wide banner (for admins).
    """
    _require_admin()
    frappe.delete_doc("Banner", banner_name, ignore_permissions=True)
    return {"status": "success", "message": "Banner deleted successfully."}


@frappe.whitelist()
def get_admin_faqs(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all FAQs (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "FAQ",
        fields=["name", "question", "faq_category", "is_active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_admin_faq(faq_data):
    """
    Creates a new FAQ (for admins).
    """
    _require_admin()
    if isinstance(faq_data, str):
        faq_data = json.loads(faq_data)

    new_faq = frappe.get_doc({
        "doctype": "FAQ",
        **faq_data
    })
    new_faq.insert(ignore_permissions=True)
    return new_faq.as_dict()


@frappe.whitelist()
def update_admin_faq(faq_name, faq_data):
    """
    Updates an FAQ (for admins).
    """
    _require_admin()
    if isinstance(faq_data, str):
        faq_data = json.loads(faq_data)

    faq = frappe.get_doc("FAQ", faq_name)
    faq.update(faq_data)
    faq.save(ignore_permissions=True)
    return faq.as_dict()


@frappe.whitelist()
def delete_admin_faq(faq_name):
    """
    Deletes an FAQ (for admins).
    """
    _require_admin()
    frappe.delete_doc("FAQ", faq_name, ignore_permissions=True)
    return {"status": "success", "message": "FAQ deleted successfully."}


@frappe.whitelist()
def get_admin_faq_categories(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all FAQ categories (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "FAQ Category",
        fields=["name", "category_name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_admin_faq_category(category_data):
    """
    Creates a new FAQ category (for admins).
    """
    _require_admin()
    if isinstance(category_data, str):
        category_data = json.loads(category_data)

    new_category = frappe.get_doc({
        "doctype": "FAQ Category",
        **category_data
    })
    new_category.insert(ignore_permissions=True)
    return new_category.as_dict()


@frappe.whitelist()
def update_admin_faq_category(category_name, category_data):
    """
    Updates an FAQ category (for admins).
    """
    _require_admin()
    if isinstance(category_data, str):
        category_data = json.loads(category_data)

    category = frappe.get_doc("FAQ Category", category_name)
    category.update(category_data)
    category.save(ignore_permissions=True)
    return category.as_dict()


@frappe.whitelist()
def delete_admin_faq_category(category_name):
    """
    Deletes an FAQ category (for admins).
    """
    _require_admin()
    frappe.delete_doc("FAQ Category", category_name, ignore_permissions=True)
    return {"status": "success", "message": "FAQ category deleted successfully."}


@frappe.whitelist()
def get_all_orders(limit_start: int = 0, limit_page_length: int = 20, status: str = None, from_date: str = None, to_date: str = None):
    """
    Retrieves a list of all orders on the platform (for admins).
    """
    _require_admin()

    filters = {}
    if status:
        filters["status"] = status
    if from_date and to_date:
        filters["creation"] = ["between", [from_date, to_date]]

    orders = frappe.get_list(
        "Order",
        filters=filters,
        fields=["name", "user", "shop", "grand_total", "status", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return orders


@frappe.whitelist()
def get_all_parcel_orders(limit_start: int = 0, limit_page_length: int = 20, status: str = None, from_date: str = None, to_date: str = None):
    """
    Retrieves a list of all parcel orders on the platform (for admins).
    """
    _require_admin()

    filters = {}
    if status:
        filters["status"] = status
    if from_date and to_date:
        filters["creation"] = ["between", [from_date, to_date]]

    parcel_orders = frappe.get_list(
        "Parcel Order",
        filters=filters,
        fields=["name", "user", "total_price", "status", "delivery_date"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )
    return parcel_orders


@frappe.whitelist()
def get_all_reviews(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all reviews on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Review",
        fields=["name", "user", "rating", "comment", "creation", "reviewable_type", "reviewable_id", "published"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def update_admin_review(review_name, review_data):
    """
    Updates a review (for admins).
    """
    _require_admin()
    if isinstance(review_data, str):
        review_data = json.loads(review_data)

    review = frappe.get_doc("Review", review_name)
    review.update(review_data)
    review.save(ignore_permissions=True)
    return review.as_dict()


@frappe.whitelist()
def delete_admin_review(review_name):
    """
    Deletes a review (for admins).
    """
    _require_admin()
    frappe.delete_doc("Review", review_name, ignore_permissions=True)
    return {"status": "success", "message": "Review deleted successfully."}


@frappe.whitelist()
def get_all_tickets(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all tickets on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Ticket",
        fields=["name", "subject", "status", "creation", "user"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def update_admin_ticket(ticket_name, ticket_data):
    """
    Updates a ticket (for admins).
    """
    _require_admin()
    if isinstance(ticket_data, str):
        ticket_data = json.loads(ticket_data)

    ticket = frappe.get_doc("Ticket", ticket_name)
    ticket.update(ticket_data)
    ticket.save(ignore_permissions=True)
    return ticket.as_dict()


@frappe.whitelist()
def get_all_order_refunds(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all order refunds on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Order Refund",
        fields=["name", "order", "status", "cause", "answer"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def update_admin_order_refund(refund_name, status, answer=None):
    """
    Updates the status and answer of an order refund (for admins).
    """
    _require_admin()

    refund = frappe.get_doc("Order Refund", refund_name)

    if status not in ["Accepted", "Canceled"]:
        frappe.throw("Invalid status. Must be 'Accepted' or 'Canceled'.")

    refund.status = status
    if answer:
        refund.answer = answer

    refund.save(ignore_permissions=True)
    return refund.as_dict()


@frappe.whitelist()
def get_all_notifications(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all notifications on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Notification Log",
        fields=["name", "subject", "document_type", "document_name", "for_user", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def get_all_languages(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all languages (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Language",
        fields=["name", "language_name", "enabled"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def update_language(language_name, language_data):
    """
    Updates a language (for admins).
    """
    _require_admin()
    if isinstance(language_data, str):
        language_data = json.loads(language_data)

    language = frappe.get_doc("Language", language_name)
    language.update(language_data)
    language.save(ignore_permissions=True)
    return language.as_dict()


@frappe.whitelist()
def get_all_currencies(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all currencies (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Currency",
        fields=["name", "currency_name", "symbol", "enabled"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def update_currency(currency_name, currency_data):
    """
    Updates a currency (for admins).
    """
    _require_admin()
    if isinstance(currency_data, str):
        currency_data = json.loads(currency_data)

    currency = frappe.get_doc("Currency", currency_name)
    currency.update(currency_data)
    currency.save(ignore_permissions=True)
    return currency.as_dict()


@frappe.whitelist()
def get_all_units(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shop units on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Shop Unit",
        fields=["name", "shop", "active"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_tags(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shop tags on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Shop Tag",
        fields=["name", "shop"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_email_settings():
    """
    Retrieves the email settings (for admins).
    """
    _require_admin()
    return frappe.get_doc("Email Settings").as_dict()


@frappe.whitelist()
def update_email_settings(settings_data):
    """
    Updates the email settings (for admins).
    """
    _require_admin()
    if isinstance(settings_data, str):
        settings_data = json.loads(settings_data)

    settings = frappe.get_doc("Email Settings")
    settings.update(settings_data)
    settings.save(ignore_permissions=True)
    return settings.as_dict()


@frappe.whitelist()
def get_deliveryman_global_settings():
    """
    Retrieves the global deliveryman settings (for admins).
    """
    _require_admin()
    return frappe.get_doc("DeliveryMan Settings").as_dict()


@frappe.whitelist()
def update_deliveryman_global_settings(settings_data):
    """
    Updates the global deliveryman settings (for admins).
    """
    _require_admin()
    if isinstance(settings_data, str):
        settings_data = json.loads(settings_data)

    settings = frappe.get_doc("DeliveryMan Settings")
    settings.update(settings_data)
    settings.save(ignore_permissions=True)
    return settings.as_dict()


@frappe.whitelist()
def get_parcel_order_settings(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all parcel order settings (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Parcel Order Setting",
        fields=["name", "title"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_parcel_order_setting(setting_data):
    """
    Creates a new parcel order setting (for admins).
    """
    _require_admin()
    if isinstance(setting_data, str):
        setting_data = json.loads(setting_data)

    new_setting = frappe.get_doc({
        "doctype": "Parcel Order Setting",
        **setting_data
    })
    new_setting.insert(ignore_permissions=True)
    return new_setting.as_dict()


@frappe.whitelist()
def update_parcel_order_setting(setting_name, setting_data):
    """
    Updates a parcel order setting (for admins).
    """
    _require_admin()
    if isinstance(setting_data, str):
        setting_data = json.loads(setting_data)

    setting = frappe.get_doc("Parcel Order Setting", setting_name)
    setting.update(setting_data)
    setting.save(ignore_permissions=True)
    return setting.as_dict()


@frappe.whitelist()
def delete_parcel_order_setting(setting_name):
    """
    Deletes a parcel order setting (for admins).
    """
    _require_admin()
    frappe.delete_doc("Parcel Order Setting", setting_name, ignore_permissions=True)
    return {"status": "success", "message": "Parcel order setting deleted successfully."}


@frappe.whitelist()
def get_all_wallet_histories(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all wallet histories on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Wallet History",
        fields=["name", "wallet", "type", "price", "status", "created_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def get_all_transactions(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all transactions on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Transaction",
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "debit", "credit", "currency"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def get_all_seller_payouts(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all seller payouts on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Seller Payout",
        fields=["name", "shop", "amount", "payout_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payout_date desc"
    )


@frappe.whitelist()
def get_all_shop_bonuses(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shop bonuses on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Shop Bonus",
        fields=["name", "shop", "amount", "bonus_date", "reason"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="bonus_date desc"
    )


@frappe.whitelist()
def get_all_order_statuses(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all order statuses on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Order Status",
        fields=["name", "status_name", "is_active", "sort_order"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="sort_order"
    )


@frappe.whitelist()
def get_all_delivery_zones(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all delivery zones on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Delivery Zone",
        fields=["name", "shop"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_request_models(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all request models on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Request Model",
        fields=["name", "model_type", "model", "status", "created_by_user", "created_at"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )

@frappe.whitelist()
def get_all_roles(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all roles on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Role",
        fields=["name", "role_name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_points(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all points on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Point",
        fields=["name", "user", "points", "reason"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_point(point_data):
    """
    Creates a new point record (for admins).
    """
    _require_admin()
    if isinstance(point_data, str):
        point_data = json.loads(point_data)

    new_point = frappe.get_doc({
        "doctype": "Point",
        **point_data
    })
    new_point.insert(ignore_permissions=True)
    return new_point.as_dict()


@frappe.whitelist()
def update_point(point_name, point_data):
    """
    Updates a point record (for admins).
    """
    _require_admin()
    if isinstance(point_data, str):
        point_data = json.loads(point_data)

    point = frappe.get_doc("Point", point_name)
    point.update(point_data)
    point.save(ignore_permissions=True)
    return point.as_dict()


@frappe.whitelist()
def delete_point(point_name):
    """
    Deletes a point record (for admins).
    """
    _require_admin()
    frappe.delete_doc("Point", point_name, ignore_permissions=True)
    return {"status": "success", "message": "Point record deleted successfully."}


@frappe.whitelist()
def get_all_translations(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all translations on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Translation",
        fields=["name", "language", "source_text", "translated_text"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_delivery_vehicle_types(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all delivery vehicle types on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Delivery Vehicle Type",
        fields=["name"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_delivery_vehicle_type(type_data):
    """
    Creates a new delivery vehicle type (for admins).
    """
    _require_admin()
    if isinstance(type_data, str):
        type_data = json.loads(type_data)

    new_type = frappe.get_doc({
        "doctype": "Delivery Vehicle Type",
        **type_data
    })
    new_type.insert(ignore_permissions=True)
    return new_type.as_dict()


@frappe.whitelist()
def update_delivery_vehicle_type(type_name, type_data):
    """
    Updates a delivery vehicle type (for admins).
    """
    _require_admin()
    if isinstance(type_data, str):
        type_data = json.loads(type_data)

    type_doc = frappe.get_doc("Delivery Vehicle Type", type_name)
    type_doc.update(type_data)
    type_doc.save(ignore_permissions=True)
    return type_doc.as_dict()


@frappe.whitelist()
def delete_delivery_vehicle_type(type_name):
    """
    Deletes a delivery vehicle type (for admins).
    """
    _require_admin()
    frappe.delete_doc("Delivery Vehicle Type", type_name, ignore_permissions=True)
    return {"status": "success", "message": "Delivery vehicle type deleted successfully."}


@frappe.whitelist()
def get_email_subscriptions(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all email subscriptions on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Email Subscription",
        fields=["name", "email"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_email_subscription(subscription_data):
    """
    Creates a new email subscription (for admins).
    """
    _require_admin()
    if isinstance(subscription_data, str):
        subscription_data = json.loads(subscription_data)

    new_subscription = frappe.get_doc({
        "doctype": "Email Subscription",
        **subscription_data
    })
    new_subscription.insert(ignore_permissions=True)
    return new_subscription.as_dict()


@frappe.whitelist()
def delete_email_subscription(subscription_name):
    """
    Deletes an email subscription (for admins).
    """
    _require_admin()
    frappe.delete_doc("Email Subscription", subscription_name, ignore_permissions=True)
    return {"status": "success", "message": "Email subscription deleted successfully."}


@frappe.whitelist()
def get_all_referrals(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all referrals on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Referral",
        fields=["name", "referrer", "referred_user", "referral_code"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_referral(referral_data):
    """
    Creates a new referral (for admins).
    """
    _require_admin()
    if isinstance(referral_data, str):
        referral_data = json.loads(referral_data)

    new_referral = frappe.get_doc({
        "doctype": "Referral",
        **referral_data
    })
    new_referral.insert(ignore_permissions=True)
    return new_referral.as_dict()


@frappe.whitelist()
def delete_referral(referral_name):
    """
    Deletes a referral (for admins).
    """
    _require_admin()
    frappe.delete_doc("Referral", referral_name, ignore_permissions=True)
    return {"status": "success", "message": "Referral deleted successfully."}


@frappe.whitelist()
def get_all_shop_tags(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shop tags on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Shop Tag",
        fields=["name", "shop"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_delivery_man_delivery_zones(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all delivery man delivery zones on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Deliveryman Delivery Zone",
        fields=["name", "deliveryman", "delivery_zone"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_email_templates(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all email templates on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Email Template",
        fields=["name", "subject", "response"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def update_email_template(template_name, template_data):
    """
    Updates an email template (for admins).
    """
    _require_admin()
    if isinstance(template_data, str):
        template_data = json.loads(template_data)

    template = frappe.get_doc("Email Template", template_name)
    template.update(template_data)
    template.save(ignore_permissions=True)
    return template.as_dict()


@frappe.whitelist()
def get_all_shop_working_days(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shop working days on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Shop Working Day",
        fields=["name", "shop", "day_of_week", "opening_time", "closing_time", "is_closed"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_shop_closed_days(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all shop closed days on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Shop Closed Day",
        fields=["name", "shop", "date"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def get_payment_payloads(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all payment payloads on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Payment Payload",
        fields=["name", "payload", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def get_sms_payloads(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all SMS payloads on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "SMS Payload",
        fields=["name", "payload", "creation"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )

@frappe.whitelist()
def get_multi_company_sales_report(from_date: str, to_date: str, company: str = None):
    """
    Retrieves a sales report for a specific company or all companies within a date range (for admins).
    """
    _require_admin()

    filters = {
        "creation": ["between", [from_date, to_date]]
    }
    if company:
        filters["shop"] = company

    sales_report = frappe.get_all(
        "Order",
        filters=filters,
        fields=["name", "shop", "user", "grand_total", "status", "creation"],
        order_by="creation desc"
    )

    # Get commission rates for all shops
    commission_rates = frappe.get_all(
        "Company",
        fields=["name", "sales_commission_rate"],
        filters={"sales_commission_rate": [">", 0]}
    )
    commission_map = {c['name']: c['sales_commission_rate'] for c in commission_rates}

    for order in sales_report:
        commission_rate = commission_map.get(order.shop, 0)
        order.commission = (order.grand_total * commission_rate) / 100

    return sales_report

@frappe.whitelist()
def get_all_product_extra_groups(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all product extra groups on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Product Extra Group",
        fields=["name", "shop"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_product_extra_values(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all product extra values on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Product Extra Value",
        fields=["name", "product_extra_group", "value", "price"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_parcel_order_settings(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all parcel order settings on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Parcel Order Setting",
        fields=["name", "title"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def get_all_payments(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all payments (credit transactions) on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Transaction",
        filters={"credit": [">", 0]},
        fields=["name", "transaction_date", "reference_doctype", "reference_name", "credit", "currency"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def get_all_payments_to_partners(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all payments to partners (payouts) on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Payout",
        fields=["name", "shop", "deliveryman", "amount", "payment_date", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="payment_date desc"
    )


@frappe.whitelist()
def get_all_bookings(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all bookings on the platform (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Booking",
        fields=["name", "user", "shop", "booking_date", "number_of_guests", "status"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="booking_date desc"
    )


@frappe.whitelist()
def create_booking(booking_data):
    """
    Creates a new booking (for admins).
    """
    _require_admin()
    if isinstance(booking_data, str):
        booking_data = json.loads(booking_data)

    new_booking = frappe.get_doc({
        "doctype": "Booking",
        **booking_data
    })
    new_booking.insert(ignore_permissions=True)
    return new_booking.as_dict()


@frappe.whitelist()
def update_booking(booking_name, booking_data):
    """
    Updates a booking (for admins).
    """
    _require_admin()
    if isinstance(booking_data, str):
        booking_data = json.loads(booking_data)

    booking = frappe.get_doc("Booking", booking_name)
    booking.update(booking_data)
    booking.save(ignore_permissions=True)
    return booking.as_dict()


@frappe.whitelist()
def delete_booking(booking_name):
    """
    Deletes a booking (for admins).
    """
    _require_admin()
    frappe.delete_doc("Booking", booking_name, ignore_permissions=True)
    return {"status": "success", "message": "Booking deleted successfully."}


@frappe.whitelist()
def get_admin_report(doctype: str, fields: str, filters: str = None, limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a report for a specified doctype with given fields and filters (for admins).
    """
    _require_admin()

    if isinstance(fields, str):
        fields = json.loads(fields)

    if filters and isinstance(filters, str):
        filters = json.loads(filters)

    return frappe.get_list(
        doctype,
        fields=fields,
        filters=filters,
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )

@frappe.whitelist()
def log_sms_payload(payload):
    """
    Logs an SMS payload.
    """
    frappe.get_doc({
        "doctype": "SMS Payload",
        "payload": payload
    }).insert(ignore_permissions=True)
    return {"status": "success"}