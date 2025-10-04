# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import os
import re
import subprocess
import logging
import json
from frappe.utils import get_sites, now, get_weekday
from packaging.version import parse as parse_version

# Setup logging
log_dir = os.path.join(frappe.conf.get("bench_path", os.getcwd()), "logs")
log_file = os.path.join(log_dir, "updater.log")
logging.basicConfig(filename=log_file, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def run_updates():
    """
    The main entry point for the new, Python-based updater script.
    """
    logging.info("--- Starting ROKCT Updater Script ---")

    bench_path = frappe.conf.get("bench_path")
    if not bench_path or not os.path.isdir(bench_path):
        logging.error(f"`bench_path` ({bench_path}) not set or invalid in site_config.json. Aborting.")
        return

    update_rokct_app(bench_path)

    if get_weekday() == "Sunday":
        migrate_control_panel_site(bench_path)

    all_sites = get_sites()
    sites_to_migrate, sites_pending_approval = get_sites_to_migrate(all_sites)

    notify_pending_approvals(sites_pending_approval)

    logging.info(f"Sites to migrate: {', '.join(sites_to_migrate)}")

    migrated_sites = []
    failed_sites = []
    locked_sites = []

    locks_dir = os.path.join(bench_path, "locks")
    os.makedirs(locks_dir, exist_ok=True)

    for site in sites_to_migrate:
        lock_path = os.path.join(locks_dir, f"{site}.lock")
        if os.path.exists(lock_path):
            locked_sites.append(site)
            logging.warning(f"Site {site} is locked. Skipping migration.")
            continue

        try:
            with open(lock_path, "w") as f:
                f.write(now())

            logging.info(f"Running migration for site: {site}")
            subprocess.run(
                ["bench", "--site", site, "migrate"],
                cwd=bench_path, check=True, capture_output=True, text=True
            )
            migrated_sites.append(site)

            subscription_name = frappe.db.get_value("Company Subscription", {"site_name": site}, "name")
            if subscription_name:
                frappe.db.set_value("Company Subscription", subscription_name, "migration_approved", 0)
                frappe.db.commit()

        except subprocess.CalledProcessError as e:
            error_log = f"Migration failed for site {site}:\n{e.stderr}"
            failed_sites.append({"site": site, "error": error_log})
            logging.error(error_log)
        finally:
            if os.path.exists(lock_path):
                os.remove(lock_path)

    notify_migration_summary(migrated_sites, failed_sites, locked_sites)

    logging.info("--- ROKCT Updater Script Finished ---")

def get_sites_to_migrate(sites):
    sites_to_migrate = []
    sites_pending_approval = []

    for site in sites:
        if site == frappe.local.site:
            continue
        try:
            subscription_name = frappe.db.get_value("Company Subscription", {"site_name": site}, "name")
            if subscription_name:
                subscription = frappe.get_doc("Company Subscription", subscription_name)
                if subscription.paas_plan:
                    if subscription.migration_approved:
                        sites_to_migrate.append(site)
                    else:
                        sites_pending_approval.append(site)
                else:
                    sites_to_migrate.append(site)
            else:
                sites_to_migrate.append(site)
        except Exception as e:
            logging.error(f"Error getting subscription for site {site}: {e}")

    return sites_to_migrate, sites_pending_approval

def update_rokct_app(bench_path):
    try:
        app_path = os.path.join(bench_path, "apps", "rokct")

        current_branch = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=app_path, text=True
        ).strip()

        logging.info(f"Fetching updates from origin for branch {current_branch}...")
        subprocess.check_output(["git", "fetch", "origin"], cwd=app_path)

        needs_update = False

        # --- New method: Check versions.json ---
        try:
            logging.info("Attempting update check using versions.json...")
            remote_versions_content = subprocess.check_output(
                ["git", "show", f"origin/{current_branch}:versions.json"],
                cwd=app_path, text=True, stderr=subprocess.PIPE
            ).strip()

            remote_versions = json.loads(remote_versions_content)

            local_versions_path = os.path.join(app_path, "versions.json")
            with open(local_versions_path, 'r') as f:
                local_versions = json.load(f)

            modules = ["rokct", "paas"]
            for module in modules:
                local_ver = local_versions.get(module)
                remote_ver = remote_versions.get(module)

                if local_ver and remote_ver and parse_version(remote_ver) > parse_version(local_ver):
                    logging.info(f"Update found for '{module}': {local_ver} -> {remote_ver} (via versions.json)")
                    needs_update = True
                    break

            if not needs_update:
                 logging.info("App is up to date (checked via versions.json).")

        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            logging.warning(f"Could not use versions.json (Error: {e}). Falling back to legacy __init__.py check.")

            # --- Legacy method: Check __init__.py on remote ---
            local_versions_path = os.path.join(app_path, "versions.json")
            if not os.path.exists(local_versions_path):
                 logging.error("Local versions.json not found. Cannot proceed with legacy check.")
                 needs_update = False
            else:
                with open(local_versions_path, 'r') as f:
                    local_versions = json.load(f)

                module_map = {"": "rokct", "paas": "paas"}
                for module_path_segment, module_name in module_map.items():
                    local_version_str = local_versions.get(module_name)

                    if not local_version_str:
                        logging.warning(f"No local version for '{module_name}' in versions.json. Skipping legacy check.")
                        continue

                    remote_init_path = os.path.join(module_path_segment, "__init__.py")

                    try:
                        remote_init_content = subprocess.check_output(
                            ["git", "show", f"origin/{current_branch}:{remote_init_path}"],
                            cwd=app_path, text=True, stderr=subprocess.PIPE
                        )

                        match = re.search(r"__version__\s*=\s*['\"]([^'\"]*)['\"]", remote_init_content)
                        remote_version_str = match.group(1) if match else None

                        if remote_version_str and parse_version(remote_version_str) > parse_version(local_version_str):
                            logging.info(f"Update found for '{module_name}': {local_version_str} -> {remote_version_str} (via legacy check)")
                            needs_update = True
                            break
                    except subprocess.CalledProcessError:
                        logging.warning(f"Remote __init__.py not found for '{module_name}' on branch '{current_branch}'. Skipping.")
                        continue

        # --- Perform update if needed ---
        if needs_update:
            logging.info(f"Pulling updates for rokct app on branch {current_branch}...")
            subprocess.run(["git", "pull", "origin", current_branch], cwd=app_path, check=True)
            logging.info("Pull successful.")
        else:
            logging.info("Rokct app and its sub-modules are up to date.")

    except Exception as e:
        logging.error(f"An unexpected error occurred during the update process: {e}", exc_info=True)


def notify_pending_approvals(sites_pending_approval):
    if not sites_pending_approval:
        return
    try:
        admin_email = frappe.db.get_value("User", "Administrator", "email")
        if not admin_email:
            logging.warning("Administrator email not found. Cannot send pending approval notification.")
            return
        message = "The following PaaS tenants are awaiting migration approval:\n\n"
        message += "\n".join([f"- {site}" for site in sites_pending_approval])
        frappe.sendmail(
            recipients=[admin_email],
            subject="PaaS Tenants Awaiting Migration Approval",
            message=message,
            now=True
        )
        logging.info(f"Sent pending approval notification to {admin_email}.")
    except Exception as e:
        logging.error(f"Failed to send pending approval notification: {e}")

def notify_migration_summary(migrated, failed, locked):
    if not migrated and not failed and not locked:
        return
    try:
        admin_email = frappe.db.get_value("User", "Administrator", "email")
        if not admin_email:
            logging.warning("Administrator email not found. Cannot send migration summary.")
            return
        message = "Migration script run summary:\n\n"
        if migrated:
            message += f"Successfully migrated sites:\n" + "\n".join([f"- {site}" for site in migrated]) + "\n\n"
        if failed:
            message += f"Failed sites:\n" + "\n".join([f"- {f['site']}: {f['error']}" for f in failed]) + "\n\n"
        if locked:
            message += f"Locked sites (skipped):\n" + "\n".join([f"- {site}" for site in locked]) + "\n\n"
        frappe.sendmail(
            recipients=[admin_email],
            subject="Daily Migration Summary",
            message=message,
            now=True
        )
        logging.info(f"Sent migration summary to {admin_email}.")
    except Exception as e:
        logging.error(f"Failed to send migration summary: {e}")

def migrate_control_panel_site(bench_path):
    site = frappe.local.site
    locks_dir = os.path.join(bench_path, "locks")
    lock_path = os.path.join(locks_dir, "control_panel.lock")
    if os.path.exists(lock_path):
        logging.warning("Control panel migration already running. Skipping.")
        return
    try:
        with open(lock_path, "w") as f:
            f.write(now())
        logging.info(f"Migrating control panel site: {site}")
        subprocess.run(["bench", "--site", site, "migrate"], cwd=bench_path, check=True)
    except subprocess.CalledProcessError as e:
        error_message = f"Control panel migration failed:\n{e.stderr}"
        logging.error(error_message)
        try:
            admin_email = frappe.db.get_value("User", "Administrator", "email")
            if admin_email:
                frappe.sendmail(
                    recipients=[admin_email],
                    subject="CRITICAL: Control Panel Migration Failed",
                    message=f"The migration for the control panel site {site} failed.\n\nError:\n{e.stderr}",
                    now=True
                )
        except Exception as mail_e:
            logging.error(f"Failed to send critical failure notification for control panel migration: {mail_e}")
    finally:
        if os.path.exists(lock_path):
            os.remove(lock_path)

