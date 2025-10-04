import frappe
import random
import json
import uuid
import csv
import io
from rokct.rokct.utils.subscription_checker import check_subscription_feature

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
def update_seller_shop(shop_data):
    """
    Updates the shop owned by the currently logged-in seller.
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