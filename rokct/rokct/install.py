import frappe
import os
import subprocess
import json

def _setup_control_panel_config():
    """
    If the current site is the designated control panel, automatically set
    the necessary configuration values in site_config.json if they don't exist.
    This is a non-interactive, fully automated setup.
    """
    if frappe.local.site != "platform.rokct.ai":
        return

    print("Detected control panel site 'platform.rokct.ai'. Verifying configuration...")

    required_config = {
        "app_role": "control_panel",
        "tenant_domain": "tenant.rokct.ai",
        "bench_path": os.path.expanduser("~/frappe-bench"),
        "tenant_site_scheme": "https",
        "etenders_api_url": "https://ocds-api.etenders.gov.za/api/OCDSReleases",
        "marketing_site_url": "https://rokct.ai"
    }

    config_changed = False
    for key, value in required_config.items():
        if not frappe.conf.get(key):
            try:
                command = ["bench", "--site", frappe.local.site, "set-config", key, value]
                subprocess.run(command, check=True, capture_output=True, text=True, cwd=frappe.conf.get("bench_path"))
                print(f"  - Set '{key}' to '{value}'")
                frappe.conf[key] = value
                config_changed = True
            except (subprocess.CalledProcessError, FileNotFoundError) as e:
                print(f"  - FAILED to set '{key}'. Error: {e}")

    if not config_changed:
        print("  - All required configurations are already set.")
    else:
        print("Configuration updated successfully.")


def _create_welcome_page():
    """Create the 'welcome' Web Page if it doesn't exist."""
    if not frappe.db.exists("Web Page", {"route": "welcome"}):
        print("Creating 'Welcome' Web Page...")
        welcome_html = """<div class="container" style="padding-top: 50px; padding-bottom: 50px;">
    <div class="text-center">
        <img src="/assets/rokct/images/logo_dark.svg" alt="ROKCT Logo" style="max-width: 150px; margin-bottom: 20px;">
        <h1>Welcome to the ROKCT Control Panel</h1>
        <p class="lead">This is the central management dashboard for your application.</p>
        <hr class="my-4">
        <p>You can manage tenants, subscriptions, and system settings from here.</p>
        <a class="btn btn-primary btn-lg" href="/app" role="button">Go to Desk</a>
    </div>
</div>"""
        frappe.get_doc({
            "doctype": "Web Page",
            "title": "Welcome",
            "route": "welcome",
            "published": 1,
            "main_section": welcome_html
        }).insert(ignore_permissions=True)
        print("'Welcome' Web Page created.")
    else:
        print("'Welcome' Web Page already exists.")


def _disable_public_signup():
    """Disable the public signup page on the control panel."""
    try:
        website_settings = frappe.get_doc("Website Settings", "Website Settings")
        if website_settings.allow_signup:
            website_settings.allow_signup = 0
            website_settings.save(ignore_permissions=True)
            print("Public signup disabled for control panel.")
        else:
            print("Public signup already disabled for control panel.")
    except Exception as e:
        frappe.log_error(f"Failed to disable public signup: {e}", "Signup Disabling Failed")


def _create_initial_roadmap_data():
    """Create initial roadmap data for the Juvo conversion project."""
    print("Creating initial roadmap data...")

    # Load backend features from JSON file
    try:
        roadmap_path = frappe.get_app_path("rokct", "paas", "fixtures", "backend_roadmap.json")
        with open(roadmap_path, "r") as f:
            backend_features = json.load(f)
    except Exception as e:
        frappe.log_error(f"Failed to read backend_roadmap.json: {e}", "Roadmap Data Creation Failed")
        return

    roadmap_items = [
        {
            "title": "Backend",
            "status": "Doing",
            "features": backend_features
        },
        {"title": "Frontend", "status": "Ideas"},
        {"title": "Web App", "status": "Ideas"},
        {"title": "Customer App", "status": "Ideas"},
        {"title": "POS App", "status": "Ideas"},
        {"title": "Manager App", "status": "Ideas"},
        {"title": "Driver App", "status": "Ideas"},
    ]

    for item in roadmap_items:
        if not frappe.db.exists("Roadmap", {"title": item["title"]}):
            try:
                doc = frappe.get_doc({
                    "doctype": "Roadmap",
                    "title": item["title"],
                    "status": item["status"]
                })
                if "features" in item:
                    for feature in item["features"]:
                        doc.append("features", {
                            "feature": feature.get("feature"),
                            "explanation": feature.get("explanation"),
                            "status": feature.get("status", "Ideas") # This is the fix
                        })
                doc.insert(ignore_permissions=True)
                print(f"  - Created roadmap item: {item['title']}")
            except Exception as e:
                frappe.log_error(f"Failed to create roadmap item '{item['title']}': {e}", "Roadmap Data Creation Failed")
        else:
            print(f"  - Roadmap item '{item['title']}' already exists.")


def after_install():
    """
    This script runs after the app is installed on a site.
    """
    print("--- Running ROKCT App Post-Installation Setup ---")

    # Step 1: Configure the control panel site if applicable.
    _setup_control_panel_config()

    # Step 2: Create the Welcome page and initial data for the control panel.
    app_role = frappe.conf.get("app_role")
    if app_role == "control_panel":
        _create_welcome_page()
        _create_initial_roadmap_data()
        _disable_public_signup()

        # Set the default workspace for System Managers
        frappe.db.set_value("Role", "System Manager", "home_page", "ROKCT Platform")
        print("Set default workspace for System Managers to 'ROKCT Platform'.")

    # Step 4: Set the homepage based on the app_role.
    if not app_role:
        print("`app_role` not set. Skipping homepage configuration.")
        return

    try:
        website_settings = frappe.get_doc("Website Settings", "Website Settings")
        homepage_changed = False
        if app_role == "control_panel" and website_settings.home_page != "welcome":
            website_settings.home_page = "welcome"
            homepage_changed = True
            print("Set homepage to 'welcome' for control panel.")

        elif app_role == "tenant" and website_settings.home_page != "tenant_home":
            website_settings.home_page = "tenant_home"
            homepage_changed = True
            print("Set homepage to 'tenant_home' for tenant.")

        if homepage_changed:
            website_settings.save(ignore_permissions=True)
            print("Homepage configuration saved.")
        else:
            print(f"Homepage already correctly set for role '{app_role}'.")

    except Exception as e:
        frappe.log_error(f"Failed to set homepage during after_install: {e}", "Homepage Configuration Failed")

    # Reorder bench apps.txt to ensure rokct is last
    try:
        bench_path = frappe.conf.get("bench_path", os.getcwd())
        apps_txt_path = os.path.join(bench_path, "sites", "apps.txt")

        if os.path.exists(apps_txt_path):
            with open(apps_txt_path, "r") as f:
                apps = [app.strip() for app in f.readlines() if app.strip()]

            if "rokct" in apps:
                if apps[-1] != "rokct":
                    apps.remove("rokct")
                    apps.append("rokct")

                    with open(apps_txt_path, "w") as f:
                        f.write("\n".join(apps))

                    print("Corrected app order in main sites/apps.txt to ensure 'rokct' is last.")
    except Exception as e:
        frappe.log_error(f"Failed to reorder main sites/apps.txt: {e}", "App Order Correction Failed")

    frappe.db.commit()
    print("--- ROKCT App Post-Installation Setup Complete ---")

