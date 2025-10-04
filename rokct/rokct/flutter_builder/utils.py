import frappe

def prevent_uninstall_if_build_active():
    """
    This function is called by the `on_uninstall` hook.
    It prevents the app from being uninstalled if there are active builds.
    """
    active_builds = frappe.get_all(
        "RQ Job",
        filters={
            "status": ["in", ["queued", "started"]],
            "method": "rokct.rokct.flutter_builder.tasks._generate_flutter_app"
        },
        limit=1
    )

    if active_builds:
        frappe.throw(
            "Cannot uninstall the Rokct app while one or more app builds are in progress. "
            "Please wait for the builds to complete or cancel them from the 'RQ Job' list."
        )

    print("No active builds found. Proceeding with uninstallation.")

