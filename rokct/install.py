import frappe
import os
import subprocess

def before_install():
    """
    This function is called before the app is installed.
    It prints a manifest of components to be installed.
    """
    print("--- Starting ROKCT App Installation ---")
    print("\n--- Pre-Installation Manifest ---")

    # --- Print DocTypes ---
    print("\nThe following DocTypes will be installed/updated:")
    try:
        app_path = frappe.get_app_path("rokct")
        doctype_path = os.path.join(app_path, "rokct", "doctype")
        if os.path.exists(doctype_path):
            for item in os.listdir(doctype_path):
                if os.path.isdir(os.path.join(doctype_path, item)):
                    print(f"- {item}")
        else:
            print("Could not find doctype directory.")
    except Exception as e:
        print(f"ERROR: Could not list DocTypes. Reason: {e}")

    # --- Print Fixtures ---
    print("\nThe following Fixtures will be installed/updated:")
    try:
        from rokct.hooks import fixtures
        if fixtures:
            for fixture in fixtures:
                print(f"- {fixture}")
        else:
            print("No fixtures found.")
    except Exception as e:
        print(f"ERROR: Could not list Fixtures. Reason: {e}")

    print("\n--- Beginning Frappe Installation Process ---")


def after_install():
    """
    This function is called after the app is installed.
    It consolidates all post-installation steps for clear, robust logging.
    """
    print("\n--- Frappe Installation Process Finished ---")

    # Manually executing seeders from the after_install hook to ensure they run.
    # This bypasses the patch system which can skip patches that have failed once.
    print("\n--- Manually Executing Data Seeders ---")
    try:
        from rokct.patches import seed_map_data, seed_subscription_plans_v4

        # Calling the execute function from each seeder module
        seed_map_data.execute()
        seed_subscription_plans_v4.execute()

        print("--- Data Seeders Finished Successfully ---")
    except Exception as e:
        print(f"FATAL ERROR during manual seeder execution: {e}")
        frappe.log_error(message=frappe.get_traceback(), title="Manual Seeder Execution Error")

    update_site_apps_txt_with_error_handling()

    set_website_homepage()

    print("\n--- ROKCT App Installation Complete ---")

def set_website_homepage():
    """
    Programmatically sets the homepage in Website Settings to ensure it is applied.
    """
    step_name = "Set Website Homepage"
    home_page_to_set = "swagger"
    print(f"--- Running Post-Install Step: {step_name} ---")
    try:
        print(f"[{step_name}] Setting Website Settings homepage to '{home_page_to_set}'.")
        website_settings = frappe.get_doc("Website Settings", "Website Settings")
        website_settings.home_page = home_page_to_set
        website_settings.save(ignore_permissions=True)
        frappe.db.commit()
        print(f"SUCCESS: [{step_name}] Successfully set homepage in Website Settings to '{home_page_to_set}'.")
    except Exception as e:
        print(f"ERROR: [{step_name}] Could not set homepage. Reason: {e}")
        frappe.log_error(f"Failed to set homepage: {e}", "Installation Error")

def update_site_apps_txt_with_error_handling():
    """
    Updates the site-specific apps.txt file with robust error handling and logging.
    """
    step_name = "Update site-specific apps.txt"
    print(f"--- Running Post-Install Step: {step_name} ---")

    if not frappe.local.site:
        print(f"[{step_name}] No site context found. Skipping.")
        return

    try:
        bench_path = frappe.conf.get("bench_path", os.getcwd())
        site_apps_txt_path = os.path.join(bench_path, "sites", frappe.local.site, "apps.txt")
        print(f"[{step_name}] Attempting to update {site_apps_txt_path}")

        installed_apps = []
        try:
            print(f"[{step_name}] Listing installed apps via 'bench' command...")
            command = ["bench", "--site", frappe.local.site, "list-apps"]
            result = subprocess.run(
                command,
                check=True,
                capture_output=True,
                text=True,
                cwd=bench_path
            )
            installed_apps = [
                line.strip().split()[0] for line in result.stdout.strip().split('\n') if line.strip()
            ]
            print(f"[{step_name}] Found apps: {', '.join(installed_apps)}")
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"ERROR: [{step_name}] 'bench list-apps' command failed. Falling back to frappe.get_installed_apps(). This may be incomplete.")
            frappe.log_error(f"[{step_name}] 'bench list-apps' command failed. Error: {e}", "Installation Error")
            installed_apps = frappe.get_installed_apps()

        if "rokct" in installed_apps:
            print(f"[{step_name}] Moving 'rokct' to the end of the list to ensure overrides.")
            installed_apps.remove("rokct")
            installed_apps.append("rokct")

        print(f"[{step_name}] Writing final app list to apps.txt...")
        with open(site_apps_txt_path, "w") as f:
            f.write("\n".join(installed_apps))

        print(f"SUCCESS: [{step_name}] Site-specific apps.txt updated successfully.")

    except Exception as e:
        print(f"FATAL ERROR: [{step_name}] An unexpected error occurred: {e}")
        frappe.log_error(message=frappe.get_traceback(), title=f"Fatal Error in {step_name}")