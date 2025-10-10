# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import os
import json
import subprocess
import shutil

def before_install():
    print("--- Starting ROKCT App Installation ---")
    print("\n--- Pre-Installation Manifest ---")
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
    print("\n--- Frappe Installation Process Finished ---")
    print("\n--- Manually Executing Data Seeders ---")
    try:
        from rokct.patches import seed_map_data, seed_subscription_plans_v4
        seed_map_data.execute()
        seed_subscription_plans_v4.execute()
        print("--- Data Seeded Finished Successfully ---")
    except Exception as e:
        print(f"FATAL ERROR during manual seeder execution: {e}")
        frappe.log_error(message=frappe.get_traceback(), title="Manual Seeder Execution Error")

    update_site_apps_txt_with_error_handling()
    set_control_panel_configs()
    setup_flutter_build_tools()
    set_website_homepage()
    print("\n--- ROKCT App Installation Complete ---")

def set_control_panel_configs():
    if frappe.local.site != "platform.rokct.ai":
        return

    print("--- Running Post-Install Step: Set Control Panel Configs ---")
    try:
        bench_path = frappe.utils.get_bench_path()
        common_config_path = os.path.join(bench_path, "sites", "common_site_config.json")
        
        if os.path.exists(common_config_path):
            with open(common_config_path, 'r') as f:
                common_config = json.load(f)
            
            db_root_password = common_config.get("db_root_password")
            if db_root_password:
                subprocess.run(["bench", "--site", frappe.local.site, "set-config", "db_root_password", db_root_password], cwd=bench_path, check=True)
                print("SUCCESS: Set 'db_root_password' in site_config.json")
            else:
                print("SKIPPED: 'db_root_password' not found in common_site_config.json, manual setup may be required.")
        else:
            print("SKIPPED: common_site_config.json not found.")

        subprocess.run(["bench", "--site", frappe.local.site, "set-config", "app_role", "control_panel"], cwd=bench_path, check=True)
        print("SUCCESS: Set 'app_role' to 'control_panel' in site_config.json")
        subprocess.run(["bench", "--site", frappe.local.site, "set-config", "tenant_domain", "tenant.rokct.ai"], cwd=bench_path, check=True)
        print("SUCCESS: Set 'tenant_domain' to 'tenant.rokct.ai' in site_config.json")

        try:
            notification_settings = frappe.get_doc("Notification Settings")
            if not notification_settings.send_from:
                admin_user = frappe.get_doc("User", "Administrator")
                if admin_user and admin_user.email:
                    notification_settings.send_from = admin_user.email
                    notification_settings.save(ignore_permissions=True)
                    print(f"SUCCESS: Set default 'Send From' email in Notification Settings to '{admin_user.email}'")
                else:
                    print("SKIPPED: Could not set default 'Send From' email, Administrator email not found.")
            else:
                print("SKIPPED: Default 'Send From' email is already set in Notification Settings.")
        except frappe.DoesNotExistError:
            print("SKIPPED: 'Notification Settings' DocType not found.")

        frappe.db.commit()
    except Exception as e:
        print(f"ERROR: Failed to set control panel configs. Reason: {e}")
        frappe.log_error(frappe.get_traceback(), "Set Control Panel Configs Error")


def set_website_homepage():
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
            result = subprocess.run(command, check=True, capture_output=True, text=True, cwd=bench_path)
            installed_apps = [line.strip().split()[0] for line in result.stdout.strip().split('\n') if line.strip()]
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


def setup_flutter_build_tools():
    """
    Checks for and installs Flutter and Android SDKs if they are missing.
    This is intended to run only on the control panel.
    """
    # This is a more robust check than using the site name.
    if frappe.conf.get("app_role") != "control_panel":
        print("--- SKIPPED: Flutter Build Tools setup is only for control panel sites. ---")
        return

    print("--- Running Post-Install Step: Setup Flutter Build Tools ---")

    try:
        # --- 0. Check for System Dependencies ---
        print("INFO: Checking for required system dependencies...")

        # Check for Java first, as it's a critical dependency for the Android SDK.
        if not shutil.which("java") and not os.environ.get("JAVA_HOME"):
            print("\n" + "="*80)
            print("ERROR: Java Development Kit (JDK) not found.")
            print("The Android SDK requires Java to be installed on your system.")
            print("Please install a JDK (version 11 or higher is recommended) and run the installation again.")
            print("Example command for Debian/Ubuntu: sudo apt-get install openjdk-17-jdk")
            print("="*80 + "\n")
            return # Stop the process if Java is missing.
        print("SUCCESS: Java installation found.")

        # Check for other tools
        required_tools = ["wget", "tar", "unzip"]
        missing_tools = [tool for tool in required_tools if not shutil.which(tool)]
        if missing_tools:
            print(f"ERROR: The following required system tools are missing: {', '.join(missing_tools)}.")
            print("Please install them using your system's package manager (e.g., 'sudo apt-get install wget tar unzip') and run the installation again.")
            return
        print("SUCCESS: All other system dependencies are present.")

        bench_path = frappe.utils.get_bench_path()
        sdk_dir = os.path.join(bench_path, "sdks")
        flutter_sdk_path = os.path.join(sdk_dir, "flutter")
        android_sdk_path = os.path.join(sdk_dir, "android")

        os.makedirs(sdk_dir, exist_ok=True)
        os.makedirs(android_sdk_path, exist_ok=True)

        # --- 1. Check/Install Flutter SDK ---
        flutter_bin_path = os.path.join(flutter_sdk_path, "bin", "flutter")
        if os.path.exists(flutter_bin_path):
            print("INFO: Flutter SDK is already installed.")
        else:
            print("INFO: Flutter SDK not found. Starting installation...")
            # Note: The URL is hardcoded as a known limitation. A more advanced solution
            # could scrape the Flutter website for the latest stable URL.
            flutter_url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz"
            flutter_archive = os.path.join(sdk_dir, "flutter.tar.xz")

            print(f"Downloading Flutter SDK from {flutter_url}...")
            subprocess.run(["wget", "-q", "-O", flutter_archive, flutter_url], check=True)

            print("Extracting Flutter SDK...")
            subprocess.run(["tar", "-xf", flutter_archive, "-C", sdk_dir], check=True)

            os.remove(flutter_archive)
            print("SUCCESS: Flutter SDK installed.")

        # --- 2. Setup Environment Variables for this process ---
        print("INFO: Setting up environment for the current process...")
        env = os.environ.copy()
        env["FLUTTER_HOME"] = flutter_sdk_path
        env["ANDROID_HOME"] = android_sdk_path
        env["PATH"] = f"{os.path.join(flutter_sdk_path, 'bin')}:{os.path.join(android_sdk_path, 'cmdline-tools', 'latest', 'bin')}:{os.path.join(android_sdk_path, 'platform-tools')}:{env['PATH']}"
        print("SUCCESS: Environment configured for this session.")

        # --- 3. Check/Install Android SDK ---
        sdkmanager_path = os.path.join(android_sdk_path, "cmdline-tools", "latest", "bin", "sdkmanager")
        if os.path.exists(sdkmanager_path):
            print("INFO: Android command-line tools are already installed.")
        else:
            print("INFO: Android command-line tools not found. Starting installation...")
            # Note: The URL is hardcoded as a known limitation.
            android_tools_url = "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
            android_archive = os.path.join(sdk_dir, "android-tools.zip")

            print(f"Downloading Android command-line tools from {android_tools_url}...")
            subprocess.run(["wget", "-q", "-O", android_archive, android_tools_url], check=True)

            print("Extracting Android command-line tools...")
            temp_extract_path = os.path.join(sdk_dir, "android-temp")
            os.makedirs(temp_extract_path, exist_ok=True)
            subprocess.run(["unzip", "-q", android_archive, "-d", temp_extract_path], check=True)

            tools_latest_path = os.path.join(android_sdk_path, "cmdline-tools", "latest")
            os.makedirs(tools_latest_path, exist_ok=True)
            # Move contents of the extracted 'cmdline-tools' directory to the 'latest' directory
            extracted_dir = os.path.join(temp_extract_path, "cmdline-tools")
            for item in os.listdir(extracted_dir):
                shutil.move(os.path.join(extracted_dir, item), os.path.join(tools_latest_path, item))

            os.remove(android_archive)
            shutil.rmtree(temp_extract_path)
            print("SUCCESS: Android command-line tools installed.")

        # --- 4. Install Android dependencies and accept licenses ---
        print("INFO: Installing required Android SDK packages and accepting licenses...")
        packages_to_install = " ".join(["platform-tools", "platforms;android-34", "build-tools;34.0.0"])

        print("Accepting Android licenses...")
        license_process = subprocess.run(f"yes | {sdkmanager_path} --licenses", shell=True, capture_output=True, text=True, env=env, check=True)
        print(license_process.stdout)

        print(f"Installing SDK packages: {packages_to_install}...")
        install_process = subprocess.run(f"{sdkmanager_path} {packages_to_install}", shell=True, capture_output=True, text=True, env=env, check=True)
        print(install_process.stdout)
        print("SUCCESS: Android SDK packages installed and licenses accepted.")

        # --- 5. Final check with flutter doctor ---
        print("INFO: Running 'flutter doctor' to verify installation...")
        doctor_process = subprocess.run([os.path.join(flutter_sdk_path, "bin", "flutter"), "doctor", "-v"], capture_output=True, text=True, env=env)
        print(doctor_process.stdout)
        if doctor_process.stderr:
            print("--- Flutter Doctor Errors/Warnings ---")
            print(doctor_process.stderr)
        print("SUCCESS: Flutter doctor check complete.")

        # --- 6. Final Instructions for User ---
        print("\n--- ACTION REQUIRED: Update Your Shell Profile ---")
        print("To make the Flutter and Android SDKs available in all future terminal sessions,")
        print("please add the following lines to your shell configuration file (e.g., ~/.profile, ~/.bashrc, or ~/.zshrc):")
        print("\n" + "#" * 50)
        print(f'export FLUTTER_HOME="{flutter_sdk_path}"')
        print(f'export ANDROID_HOME="{android_sdk_path}"')
        print('export PATH="$PATH:$FLUTTER_HOME/bin"')
        print('export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"')
        print("#" * 50 + "\n")
        print("After adding these lines, run 'source ~/.profile' (or your shell's equivalent) or restart your terminal.")

    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"\nERROR: A command failed during Flutter setup. Reason: {e}")
        if hasattr(e, 'stdout') and e.stdout:
            print(f"STDOUT: {e.stdout}")
        if hasattr(e, 'stderr') and e.stderr:
            print(f"STDERR: {e.stderr}")
        frappe.log_error(message=frappe.get_traceback(), title="Flutter Build Tools Setup Error")
    except Exception as e:
        print(f"\nFATAL ERROR during Flutter setup: {e}")
        frappe.log_error(message=frappe.get_traceback(), title="Flutter Build Tools Setup Error")