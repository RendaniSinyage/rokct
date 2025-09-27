import frappe
import os
import subprocess

def before_install():
    """
    This function is called before the app is installed.
    """
    print("--- Starting ROKCT App Installation ---")

def after_install():
    """
    This function is called after the app is installed.
    It consolidates all post-installation steps for clear, robust logging.
    """
    # The data seeder patch will run automatically via patches.txt.
    # The patch file itself contains print statements for verbosity.

    update_site_apps_txt_with_error_handling()

    print("--- ROKCT App Installation Complete ---")

def update_site_apps_txt_with_error_handling():
    """
    Updates the site-specific apps.txt file with robust error handling and logging.
    """
    step_name = "Update site-specific apps.txt"
    print(f"--- Running Step: {step_name} ---")

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