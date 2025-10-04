# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
from frappe.utils import now_datetime

@frappe.whitelist()
def remove_expired_stories():
    """
    Find and delete stories that have expired.
    This is run daily by the scheduler on tenant sites.
    """
    if frappe.conf.get("app_role") != "tenant":
        return

    print("Running Daily Expired Stories Cleanup Job...")

    expired_stories = frappe.get_all("Story",
        filters={
            "expires_at": ["<", now_datetime()]
        },
        pluck="name"
    )

    if not expired_stories:
        print("No expired stories to delete.")
        return

    print(f"Found {len(expired_stories)} expired stories to delete...")

    for story_name in expired_stories:
        try:
            frappe.delete_doc("Story", story_name, ignore_permissions=True, force=True)
            print(f"  - Deleted expired story: {story_name}")
        except Exception as e:
            frappe.log_error(frappe.get_traceback(), f"Failed to delete expired story {story_name}")

    frappe.db.commit()
    print("Expired Stories Cleanup Job Complete.")

