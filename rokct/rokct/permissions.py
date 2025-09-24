import frappe

def sync_user_roles_on_login(login_manager):
    """
    Called on login on a tenant site.
    It calls the control plane to get the subscription status and syncs the user's module roles.
    """
    # 1. Only run on tenant sites
    if frappe.conf.get("app_role") != "tenant":
        return

    user_doc = frappe.get_doc("User", login_manager.user)

    # Skip role sync for System Managers, as they should have all access.
    if "System Manager" in [role.role for role in user_doc.roles]:
        return

    try:
        # 2. Call the control plane API
        # The control plane URL should be stored in the site config for security and flexibility.
        control_plane_url = frappe.conf.get("control_plane_url")
        if not control_plane_url:
            frappe.log_error("control_plane_url not set in site_config.json", "Role Sync Failed")
            return

        api_url = f"{control_plane_url}/api/method/rokct.control_panel.api.get_subscription_status"

        api_secret = frappe.conf.get("api_secret")
        if not api_secret:
            frappe.log_error("api_secret not set in site_config.json", "Role Sync Failed")
            return

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_secret}"
        }

        response = frappe.make_post_request(api_url, headers=headers)
        subscription_data = response.get('message')

        if not subscription_data or subscription_data.get("status") not in ["Active", "Trialing"]:
            # If subscription is not active, remove all module roles.
            current_module_roles = [role.role for role in user_doc.roles if role.role.startswith("Module:")]
            if current_module_roles:
                user_doc.remove_roles(*current_module_roles)
            return

        # 3. Sync roles based on the response
        allowed_module_names = subscription_data.get("modules", [])
        expected_roles = set(["Module: " + name for name in allowed_module_names])
        current_roles = set([role.role for role in user_doc.roles if role.role.startswith("Module:")])

        roles_to_add = expected_roles - current_roles
        roles_to_remove = current_roles - expected_roles

        if roles_to_add:
            user_doc.add_roles(*roles_to_add)
            print(f"Adding roles to {user_doc.name}: {roles_to_add}")

        if roles_to_remove:
            user_doc.remove_roles(*roles_to_remove)
            print(f"Removing roles from {user_doc.name}: {roles_to_remove}")

        # 4. Handle company creation permission (as per user request)
        max_companies = subscription_data.get("max_companies", 1)
        company_creation_role = "Company Creator" # A new role we can create for this purpose

        has_creation_role = company_creation_role in [role.role for role in user_doc.roles]

        if max_companies > 1 and not has_creation_role:
            user_doc.add_roles(company_creation_role)
            print(f"Adding company creation role to {user_doc.name}")
        elif max_companies <= 1 and has_creation_role:
            user_doc.remove_roles(company_creation_role)
            print(f"Removing company creation role from {user_doc.name}")


    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "User Role Sync Failed")

