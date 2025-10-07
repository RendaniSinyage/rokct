# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
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
from rokct.rokct.utils.subscription_checker import check_subscription_feature
from rokct.rokct.tenant.api import get_subscription_details
from rokct.paas.api.shop.shop import get_shops, get_shop_details
from rokct.paas.api.product.product import (
    get_products,
    most_sold_products,
    get_discounted_products,
    get_products_by_ids,
    get_product_by_uuid,
    get_product_by_slug,
    read_product_file,
    get_product_reviews,
    order_products_calculate,
    get_products_by_brand,
    products_search,
    get_products_by_category,
    get_products_by_shop,
    add_product_review,
    get_product_history
)
from rokct.paas.api.category.category import (
    get_categories,
    get_category_types,
    get_children_categories,
    search_categories,
    get_category_by_uuid,
    create_category,
    update_category,
    delete_category
)
from rokct.paas.api.brand.brand import (
    get_brands,
    get_brand_by_uuid,
    create_brand,
    update_brand,
    delete_brand
)
from rokct.paas.api.user.user import (
    logout,
    check_phone,
    send_phone_verification_code,
    verify_phone_code,
    register_user,
    forgot_password,
    get_user_membership,
    get_user_membership_history,
    get_user_parcel_orders,
    get_user_parcel_order,
    get_user_addresses,
    get_user_address,
    add_user_address,
    update_user_address,
    delete_user_address,
    get_user_invites,
    create_invite,
    update_invite_status,
    get_user_wallet,
    get_wallet_history,
    export_orders,
    register_device_token,
    get_user_transactions,
    get_user_shop,
    update_seller_shop,
    get_user_request_models,
    create_request_model,
    get_user_tickets,
    get_user_ticket,
    create_ticket,
    reply_to_ticket,
    get_user_profile,
    update_user_profile,
    get_user_order_refunds,
    create_order_refund,
    get_user_notifications,
)
from rokct.paas.api.payment.payment import (
    get_payment_gateways,
    get_payment_gateway,
    initiate_flutterwave_payment,
    flutterwave_callback,
    get_payfast_settings,
    handle_payfast_callback,
    process_payfast_token_payment,
    save_payfast_card,
    get_saved_payfast_cards,
    delete_payfast_card,
    handle_paypal_callback,
    initiate_paypal_payment,
    initiate_paystack_payment,
    handle_paystack_callback,
    log_payment_payload,
    handle_stripe_webhook,
)
from rokct.paas.api.cart.cart import (
    get_cart,
    add_to_cart,
    remove_from_cart,
    calculate_cart_totals,
)
from rokct.paas.api.order.order import (
    create_order,
    list_orders,
    get_order_details,
    update_order_status,
    add_order_review,
    cancel_order,
    get_order_statuses,
)
from rokct.paas.api.receipt.receipt import (
    get_receipts,
    get_receipt,
)
from rokct.paas.api.blog.blog import (
    get_admin_blogs,
    create_admin_blog,
    update_admin_blog,
    delete_admin_blog,
    get_blogs,
    get_blog,
)
from rokct.paas.api.career.career import (
    get_careers,
    get_career,
    get_admin_careers,
)
from rokct.paas.api.page.page import (
    get_page,
    get_admin_pages,
    get_admin_web_page,
    update_admin_web_page,
)
from rokct.paas.api.delivery.delivery import (
    is_point_in_polygon,
    get_delivery_zone_by_shop,
    check_delivery_zone,
    get_delivery_points,
    get_delivery_point,
)
from rokct.paas.api.branch.branch import (
    get_branches,
    get_branch,
    create_branch,
    update_branch,
    delete_branch,
)
from rokct.paas.api.parcel.parcel import (
    create_parcel_order,
)
from rokct.paas.api.booking.booking import (
    create_booking,
    get_booking,
    update_booking,
    delete_booking,
    create_shop_section,
    get_shop_section,
    update_shop_section,
    delete_shop_section,
    create_table,
    get_table,
    update_table,
    delete_table,
    get_user_bookings,
    update_user_booking_status,
    get_shop_bookings,
    get_shop_sections_for_booking,
    get_tables_for_section,
    create_user_booking,
    get_my_bookings,
    cancel_my_booking,
    get_shop_user_bookings,
    update_shop_user_booking_status,
    manage_shop_booking_working_days,
    manage_shop_booking_closed_dates,
)
from rokct.paas.api.admin_reports.admin_reports import (
    get_admin_statistics,
    get_multi_company_sales_report,
    get_admin_report,
    get_all_wallet_histories,
    get_all_transactions,
    get_all_seller_payouts,
    get_all_shop_bonuses,
)
from rokct.paas.api.admin_management.admin_management import (
    get_all_shops,
    create_shop,
    update_shop,
    delete_shop,
    get_all_users,
    get_all_roles,
)
from rokct.paas.api.admin_content.admin_content import (
    get_admin_stories,
    get_admin_banners,
    create_admin_banner,
    update_admin_banner,
    delete_admin_banner,
    get_admin_faqs,
    create_admin_faq,
    update_admin_faq,
    delete_admin_faq,
    get_admin_faq_categories,
    create_admin_faq_category,
    update_admin_faq_category,
    delete_admin_faq_category,
)
from rokct.paas.api.admin_records.admin_records import (
    get_all_orders,
    get_all_parcel_orders,
    get_all_reviews,
    update_admin_review,
    delete_admin_review,
    get_all_tickets,
    update_admin_ticket,
    get_all_order_refunds,
    update_admin_order_refund,
    get_all_notifications,
    get_all_bookings,
    create_booking,
    update_booking,
    delete_booking,
    get_all_request_models,
    get_all_order_statuses,
)
from rokct.paas.api.admin_settings.admin_settings import (
    get_all_languages,
    update_language,
    get_all_currencies,
    update_currency,
    get_email_settings,
    update_email_settings,
    get_all_email_templates,
    update_email_template,
    get_email_subscriptions,
    create_email_subscription,
    delete_email_subscription,
)
from rokct.paas.api.admin_data.admin_data import (
    get_all_units,
    get_all_tags,
    get_all_points,
    create_point,
    update_point,
    delete_point,
    get_all_translations,
    get_all_referrals,
    create_referral,
    delete_referral,
    get_all_shop_tags,
    get_all_product_extra_groups,
    get_all_product_extra_values,
)
from rokct.paas.api.admin_logistics.admin_logistics import (
    get_deliveryman_global_settings,
    update_deliveryman_global_settings,
    get_parcel_order_settings,
    create_parcel_order_setting,
    update_parcel_order_setting,
    delete_parcel_order_setting,
    get_all_delivery_zones,
    get_delivery_vehicle_types,
    create_delivery_vehicle_type,
    update_delivery_vehicle_type,
    delete_delivery_vehicle_type,
    get_all_delivery_man_delivery_zones,
    get_all_shop_working_days,
    get_all_shop_closed_days,
)
from rokct.paas.api.seller_shop_settings.seller_shop_settings import (
    get_seller_shop_working_days,
    update_seller_shop_working_days,
    get_seller_shop_closed_days,
    add_seller_shop_closed_day,
    delete_seller_shop_closed_day,
    get_shop_users,
    add_shop_user,
    remove_shop_user,
    get_seller_branches,
    create_seller_branch,
    update_seller_branch,
    delete_seller_branch,
    get_seller_deliveryman_settings,
    update_seller_deliveryman_settings,
)
from rokct.paas.api.seller_marketing.seller_marketing import (
    get_seller_coupons,
    create_seller_coupon,
    update_seller_coupon,
    delete_seller_coupon,
    get_seller_discounts,
    create_seller_discount,
    update_seller_discount,
    delete_seller_discount,
    get_seller_banners,
    create_seller_banner,
    update_seller_banner,
    delete_seller_banner,
    get_ads_packages,
    get_seller_shop_ads_packages,
    purchase_shop_ads_package,
)
from rokct.paas.api.seller_operations.seller_operations import (
    get_seller_kitchens,
    create_seller_kitchen,
    update_seller_kitchen,
    delete_seller_kitchen,
    get_seller_inventory_items,
    adjust_seller_inventory,
    get_seller_menus,
    get_seller_menu,
    create_seller_menu,
    update_seller_menu,
    delete_seller_menu,
    get_seller_receipts,
    create_seller_receipt,
    update_seller_receipt,
    delete_seller_receipt,
    get_seller_combos,
    get_seller_combo,
    create_seller_combo,
    update_seller_combo,
    delete_seller_combo,
)
from rokct.paas.api.seller_reports.seller_reports import (
    get_seller_statistics,
    get_seller_sales_report,
)
from rokct.paas.api.seller_order.seller_order import (
    get_seller_orders,
    get_seller_order_refunds,
    update_seller_order_refund,
    get_seller_reviews,
)
from rokct.paas.api.seller_product.seller_product import (
    get_seller_products,
    create_seller_product,
    update_seller_product,
    delete_seller_product,
    get_seller_categories,
    create_seller_category,
    update_seller_category,
    delete_seller_category,
    get_seller_brands,
    create_seller_brand,
    update_seller_brand,
    delete_seller_brand,
    get_seller_extra_groups,
    create_seller_extra_group,
    update_seller_extra_group,
    delete_seller_extra_group,
    get_seller_extra_values,
    create_seller_extra_value,
    update_seller_extra_value,
    delete_seller_extra_value,
    get_seller_units,
    create_seller_unit,
    update_seller_unit,
    delete_seller_unit,
    get_seller_tags,
    create_seller_tag,
    update_seller_tag,
    delete_seller_tag,
)
from rokct.paas.api.seller_payout.seller_payout import (
    get_seller_payouts,
)
from rokct.paas.api.seller_bonus.seller_bonus import (
    get_seller_bonuses,
)
from rokct.paas.api.seller_story.seller_story import (
    get_seller_stories,
    create_seller_story,
    update_seller_story,
    delete_seller_story,
)
from rokct.paas.api.seller_delivery_zone.seller_delivery_zone import (
    get_seller_delivery_zones,
    get_seller_delivery_zone,
    create_seller_delivery_zone,
    update_seller_delivery_zone,
    delete_seller_delivery_zone,
)
from rokct.paas.api.seller_invites.seller_invites import (
    get_seller_invites,
)
from rokct.paas.api.seller_transactions.seller_transactions import (
    get_seller_transactions,
    get_seller_shop_payments,
    get_seller_payment_to_partners,
)
from rokct.paas.api.seller_shop_gallery.seller_shop_gallery import (
    get_seller_shop_galleries,
    create_seller_shop_gallery,
    delete_seller_shop_gallery,
)
from rokct.paas.api.seller_customer_management.seller_customer_management import (
    get_seller_request_models,
    get_seller_customer_addresses,
)
from rokct.paas.api.seller_logistics.seller_logistics import (
    get_seller_delivery_man_delivery_zones,
    adjust_seller_inventory,
)
from rokct.paas.api.delivery_man.delivery_man import (
    get_deliveryman_orders,
    get_deliveryman_parcel_orders,
    get_deliveryman_settings,
    update_deliveryman_settings,
    get_deliveryman_statistics,
    get_banned_shops,
    get_payment_to_partners,
    get_deliveryman_order_report,
    get_deliveryman_delivery_zones,
)
from rokct.paas.api.waiter.waiter import (
    get_waiter_orders,
    get_waiter_order_report,
)
from rokct.paas.api.cook.cook import (
    get_cook_orders,
    get_cook_order_report,
)
from rokct.paas.api.notification.notification import (
    send_push_notification,
    log_sms_payload,
)
from rokct.paas.api.coupon.coupon import check_coupon
from rokct.paas.api.system.system import (
    get_weather,
    api_status,
    get_languages,
    get_currencies,
)