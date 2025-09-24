import frappe
import os
import subprocess

def update_site_apps_txt(*args, **kwargs):
    """
    Updates the site-specific apps.txt file to be in sync with the list of
    apps actually installed on the site.

    This function is intended to be called from hooks like after_install,
    after_app_install, and after_app_uninstall.
    """
    # This function can be called from a hook that is not site-specific,
    # so we need to ensure we have a site context.
    if not frappe.local.site:
        return

    print(f"--> Running update_site_apps_txt for site: {frappe.local.site}")

    try:
        bench_path = frappe.conf.get("bench_path", os.getcwd())
        site_apps_txt_path = os.path.join(bench_path, "sites", frappe.local.site, "apps.txt")

        # Get the definitive list of installed apps by running `bench list-apps`.
        try:
            command = ["bench", "--site", frappe.local.site, "list-apps"]
            result = subprocess.run(
                command,
                check=True,
                capture_output=True,
                text=True,
                cwd=bench_path
            )
            # The output of `list-apps` includes version info, so parse each line
            # to get just the first word (the app name).
            installed_apps = [
                line.strip().split()[0] for line in result.stdout.strip().split('\n') if line.strip()
            ]
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"--> ERROR: Failed to list apps via bench command: {e}")
            print("--> Falling back to frappe.get_installed_apps(). This may be incomplete.")
            installed_apps = frappe.get_installed_apps()

        # Ensure rokct is last for override
        if "rokct" in installed_apps:
            installed_apps.remove("rokct")
            installed_apps.append("rokct")

        with open(site_apps_txt_path, "w") as f:
            f.write("\n".join(installed_apps))

        print(f"--> Successfully updated site-specific apps.txt: {site_apps_txt_path}")

    except Exception as e:
        # Broad exception to ensure this hook doesn't crash the installation process.
        print(f"--> FATAL ERROR in update_site_apps_txt: {e}")

