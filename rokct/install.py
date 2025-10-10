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

    # Run configs first to ensure database password is set
    set_control_panel_configs()

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
    Checks for and installs a complete Flutter build environment based on versions.json.
    This is intended to run only on the control panel.
    It will skip the setup if the currently installed versions match the required versions.
    """
    if frappe.conf.get("app_role") != "control_panel":
        print("--- SKIPPED: Flutter Build Tools setup is only for control panel sites. ---")
        return

    print("--- Running Post-Install Step: Setup Flutter Build Tools ---")

    try:
        # --- 1. Version and Path Setup ---
        bench_path = frappe.utils.get_bench_path()
        sdk_dir = os.path.join(bench_path, "sdks")
        os.makedirs(sdk_dir, exist_ok=True) # Ensure sdks dir exists

        app_path = frappe.get_app_path("rokct")
        required_versions_path = os.path.join(app_path, "versions.json")
        installed_versions_path = os.path.join(sdk_dir, ".flutter_versions_installed.json")

        with open(required_versions_path, 'r') as f:
            required_versions = json.load(f)

        # --- 2. Version Comparison ---
        installed_versions = {}
        if os.path.exists(installed_versions_path):
            try:
                with open(installed_versions_path, 'r') as f:
                    installed_versions = json.load(f)
                print("INFO: Currently installed versions:")
                for key, value in installed_versions.items():
                    print(f"  - {key}: {value}")
            except (json.JSONDecodeError, IOError):
                print("WARNING: Could not read installed versions file. Assuming fresh install.")
                installed_versions = {}

        print("INFO: Required versions:")
        for key, value in required_versions.items():
            print(f"  - {key}: {value}")

        if required_versions == installed_versions:
            print("\n✅ SUCCESS: Required versions are already installed and up-to-date. Skipping setup.")
            return
        else:
            print("\nINFO: New versions detected or previous installation was incomplete. Proceeding with setup...")


        # --- 3. Read Configuration ---
        flutter_version = required_versions["flutter_sdk_version"]
        android_platform = required_versions["android_platform"]
        android_build_tools = required_versions["android_build_tools"]
        jdk_package = required_versions["jdk_package"]

        flutter_url = f"https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_{flutter_version}.tar.xz"
        android_tools_url = "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"


        # --- 4. Check and Install System Dependencies ---
        print("INFO: Checking for required system dependencies...")

        deps_to_install = []
        if not shutil.which("java"):
            deps_to_install.append(jdk_package)

        other_deps = ["wget", "tar", "unzip", "clang", "cmake", "ninja-build"]
        for dep in other_deps:
            if not shutil.which(dep):
                deps_to_install.append(dep)

        if deps_to_install:
            print(f"INFO: The following dependencies are missing: {', '.join(deps_to_install)}. Attempting to install...")

            # --- Automated Password Handling (as per user instruction) ---
            db_root_password = None
            try:
                common_config_path = os.path.join(bench_path, "sites", "common_site_config.json")
                if os.path.exists(common_config_path):
                    with open(common_config_path, 'r') as f:
                        common_config = json.load(f)
                    db_root_password = common_config.get("db_root_password")
            except Exception as e:
                print(f"WARNING: Could not read database password. Will fall back to interactive prompt. Reason: {e}")

            install_successful = False
            if db_root_password:
                print("INFO: Attempting automatic installation using stored password...")
                # Use shell=True to allow the pipe to work. Note the security implications.
                update_proc = subprocess.run(f'echo "{db_root_password}" | sudo -S apt-get update -y', shell=True, capture_output=True, text=True)
                if update_proc.returncode == 0:
                    install_proc = subprocess.run(f'echo "{db_root_password}" | sudo -S apt-get install -y {" ".join(deps_to_install)}', shell=True, capture_output=True, text=True)
                    if install_proc.returncode == 0:
                        install_successful = True
                        print("SUCCESS: Automatic installation of system dependencies was successful.")
                    else:
                        print("WARNING: Automatic installation failed. The provided password might be incorrect.")
                        print(f"         Stderr: {install_proc.stderr.strip()}")
                else:
                    print("WARNING: Automatic repository update failed. The provided password might be incorrect.")
                    print(f"         Stderr: {update_proc.stderr.strip()}")

            if not install_successful:
                print("INFO: Falling back to standard interactive password prompt for installation.")
                try:
                    # Run commands interactively, allowing user to see prompts.
                    subprocess.run(["sudo", "apt-get", "update", "-y"], check=True)
                    subprocess.run(["sudo", "apt-get", "install", "-y"] + deps_to_install, check=True)
                    print("SUCCESS: All system dependencies installed via interactive prompt.")
                except (subprocess.CalledProcessError, Exception) as e:
                    print(f"\nERROR: Interactive installation of system dependencies failed. Stderr: {e.stderr.decode() if hasattr(e, 'stderr') else e}")
                    print(f"Please install the following packages manually: {', '.join(deps_to_install)}")
                    return
        else:
            print("SUCCESS: All system dependencies are present.")

        # --- 5. Setup SDK Directories ---
        flutter_sdk_path = os.path.join(sdk_dir, "flutter")
        android_sdk_path = os.path.join(sdk_dir, "android")

        # --- 6. Install Flutter SDK ---
        # This is a destructive but reliable way to ensure the correct version is installed.
        print(f"INFO: Ensuring Flutter SDK version {flutter_version} is installed...")
        if os.path.exists(flutter_sdk_path):
            shutil.rmtree(flutter_sdk_path)

        archive = os.path.join(sdk_dir, "flutter.tar.xz")
        subprocess.run(["wget", "-q", "-O", archive, flutter_url], check=True)
        subprocess.run(["tar", "-xf", archive, "-C", sdk_dir], check=True, stdout=subprocess.DEVNULL)
        os.remove(archive)
        print("SUCCESS: Flutter SDK installed.")


        # --- 7. Install Android SDK ---
        sdkmanager_path = os.path.join(android_sdk_path, "cmdline-tools", "latest", "bin", "sdkmanager")
        # This is a destructive but reliable way to ensure the correct version is installed.
        print("INFO: Ensuring Android command-line tools are installed...")
        if os.path.exists(os.path.join(android_sdk_path, "cmdline-tools")):
            shutil.rmtree(os.path.join(android_sdk_path, "cmdline-tools"))

        archive = os.path.join(sdk_dir, "android-tools.zip")
        subprocess.run(["wget", "-q", "-O", archive, android_tools_url], check=True)
        temp_extract_path = os.path.join(sdk_dir, "android-temp")
        os.makedirs(temp_extract_path, exist_ok=True)
        shutil.unpack_archive(archive, temp_extract_path)

        tools_latest_path = os.path.join(android_sdk_path, "cmdline-tools", "latest")
        os.makedirs(tools_latest_path, exist_ok=True)
        extracted_dir = os.path.join(temp_extract_path, "cmdline-tools")
        for item in os.listdir(extracted_dir):
            shutil.move(os.path.join(extracted_dir, item), os.path.join(tools_latest_path, item))

        os.remove(archive)
        shutil.rmtree(temp_extract_path)
        print("SUCCESS: Android command-line tools installed.")


        # --- 8. Install Android Packages ---
        env = os.environ.copy()
        env["ANDROID_HOME"] = android_sdk_path
        env["FLUTTER_HOME"] = flutter_sdk_path
        env["PATH"] = f"{os.path.join(flutter_sdk_path, 'bin')}:{os.path.dirname(sdkmanager_path)}:{os.path.join(android_sdk_path, 'platform-tools')}:{env['PATH']}"

        print("INFO: Installing required Android SDK packages and accepting licenses...")
        packages_to_install = ["platform-tools", f"platforms;android-{android_platform}", f"build-tools;{android_build_tools}"]
        subprocess.run(f"yes | {sdkmanager_path} --licenses", shell=True, env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        for package in packages_to_install:
            subprocess.run([sdkmanager_path, package], env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        print("SUCCESS: All Android SDK packages installed and licenses accepted.")

        # --- 9. Configure User's PATH ---
        print("INFO: Configuring user's PATH in ~/.bashrc...")
        try:
            import pwd
            uid = os.stat(bench_path).st_uid
            user_info = pwd.getpwuid(uid)
            home_dir = user_info.pw_dir
            bashrc_path = os.path.join(home_dir, ".bashrc")

            exports = [
                f'\n# ROKCT Build Environment',
                f'export ANDROID_HOME="{android_sdk_path}"',
                f'export FLUTTER_HOME="{flutter_sdk_path}"',
                f'export PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"',
            ]

            if not os.path.exists(bashrc_path):
                open(bashrc_path, 'a').close()
                os.chown(bashrc_path, uid, user_info.pw_gid)
                print(f"INFO: ~/.bashrc not found. Created a new one at {bashrc_path}")

            with open(bashrc_path, "r+") as f:
                content = f.read()
                if exports[0] not in content:
                    f.write("\n".join(exports) + "\n")
                    print(f"SUCCESS: PATH variables added to {bashrc_path}.")
                else:
                    print(f"INFO: PATH variables already exist in {bashrc_path}.")

        except (ImportError, KeyError, OSError) as e:
            print(f"WARNING: Could not automatically update shell configuration. Reason: {e}")
            print("Please add the following lines to your shell configuration file (e.g., ~/.bashrc):")
            print("\n".join(exports))

        # --- 10. Final Verification ---
        print("INFO: Running 'flutter doctor' to verify installation...")
        doctor_process = subprocess.run([os.path.join(flutter_sdk_path, "bin", "flutter"), "doctor"], capture_output=True, text=True, env=env)
        doctor_output = doctor_process.stdout

        if "[✓] Android toolchain" in doctor_output:
            print("SUCCESS: Flutter doctor reports a healthy Android toolchain.")
        else:
            print("WARNING: Flutter doctor reported issues. Please review the output below:")
            print(doctor_output)

        print("\n" + "="*80)
        print("✅ SUCCESS: Flutter and Android build tools are installed and ready for the system.")
        print("\nIMPORTANT: To apply the new environment variables, you must either:")
        print("  1. Close and reopen your terminal session.")
        print("  2. Run the command: source ~/.bashrc")
        print("="*80)

        # --- 11. Create/Update Lock File ---
        with open(installed_versions_path, "w") as f:
            json.dump(required_versions, f, indent=4)
        print(f"INFO: Updated version lock file at {installed_versions_path}")

    except Exception as e:
        print(f"\nFATAL ERROR during Flutter setup: {e}")
        import traceback
        traceback.print_exc()
        frappe.log_error(message=frappe.get_traceback(), title="Flutter Build Tools Setup Error")