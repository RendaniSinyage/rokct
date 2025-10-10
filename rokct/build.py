import frappe
import os
import subprocess

def build_frontend():
    """
    Builds the frontend assets if the site is a control panel.
    This is triggered by the on_install and on_update hooks.
    """
    if frappe.conf.get("app_role") != "control_panel":
        print("Skipping frontend build for non-control panel site.")
        return

    print("Control panel site detected, starting frontend build...")

    # Use frappe.get_app_path to reliably find the app's root directory
    app_path = frappe.get_app_path("rokct", "..", "..")

    try:
        # First, install dependencies
        print(f"Running 'yarn install' in {app_path}...")
        subprocess.run(
            ["yarn", "install"],
            cwd=app_path,
            check=True,
            capture_output=True,
            text=True
        )
        print("Dependencies installed successfully.")

        # Then, build the assets
        print(f"Running 'yarn build' in {app_path}...")
        build_process = subprocess.run(
            ["yarn", "build"],
            cwd=app_path,
            check=True,
            capture_output=True,
            text=True
        )
        print("Frontend built successfully.")
        print(build_process.stdout)

    except FileNotFoundError:
        print("Error: 'yarn' command not found. Please ensure yarn is installed and in the system's PATH.")
        frappe.log_error("Yarn not found during frontend build.")
    except subprocess.CalledProcessError as e:
        print(f"An error occurred during the build process. Return code: {e.returncode}")
        print("Stdout:")
        print(e.stdout)
        print("Stderr:")
        print(e.stderr)
        frappe.log_error(f"Frontend build failed.\nSTDOUT: {e.stdout}\nSTDERR: {e.stderr}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        frappe.log_error(f"An unexpected error occurred during frontend build: {e}")