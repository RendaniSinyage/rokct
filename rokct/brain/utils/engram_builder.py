# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import json
from frappe.utils import getdate
from rokct.rokct.utils.subscription_checker import check_subscription_feature

def get_document_title(doctype, name):
    """ Fetches the title of a document based on common title fields. """
    if not frappe.db.exists(doctype, name):
        return name
    try:
        title_fields = ["title", "subject", "full_name", "name"]
        doc_meta = frappe.get_meta(doctype)
        for field in title_fields:
            if doc_meta.has_field(field):
                return frappe.db.get_value(doctype, name, field) or name
        return name
    except Exception:
        return name

@check_subscription_feature("Memory")
def process_event_in_realtime(doc, method):
    """
    This is the main "storytelling engine". It's called by hooks and
    instantly updates the Engram for a document in real-time.
    """
    # --- Exclusion Logic ---
    ignored_doctypes = ["Engram", "API Error Log"]
    if doc.doctype in ignored_doctypes:
        return
    try:
        module = frappe.db.get_value("DocType", doc.doctype, "module")
        if module in ["paas", "swagger", "brain"]:
            return
    except Exception:
        pass

    try:
        # Determine event details
        if doc.doctype == "Email Queue":
            if doc.status != "Sent":
                return
            event_name = "Emailed"
            ref_doctype = doc.reference_doctype
            ref_name = doc.reference_name
            user_name = frappe.db.get_value("User", doc.owner, "full_name") or doc.owner
        else:
            event_name = method.replace('on_', '').capitalize()
            ref_doctype = doc.doctype
            ref_name = doc.name
            user_name = frappe.db.get_value("User", frappe.session.user, "full_name") or frappe.session.user

        # Get or Create Engram
        engram_name = f"{ref_doctype}-{ref_name}"
        try:
            engram_doc = frappe.get_doc("Engram", engram_name)
        except frappe.DoesNotExistError:
            engram_doc = frappe.new_doc("Engram")
            engram_doc.reference_doctype = ref_doctype
            engram_doc.reference_name = ref_name
            engram_doc.name = engram_name
            engram_doc.reference_title = get_document_title(ref_doctype, ref_name)

        # --- Real-Time Storytelling Logic ---
        event_date = getdate(doc.modified).strftime("%Y-%m-%d")

        # Check if the last line of the summary is for the same user and date
        last_line = engram_doc.summary.split('\n')[-1] if engram_doc.summary else ""

        if f"by {user_name} on {event_date}" in last_line:
            # The same user acted on the same day, so we compound the event
            if event_name not in last_line:
                # Add the new action to the existing line
                # This is a more robust way to handle the grammar
                actions = last_line.split(f" by {user_name}")[0].split(", ")
                actions.append(event_name)
                # Remove duplicates and sort
                actions = sorted(list(set(actions)))
                if len(actions) > 1:
                    action_str = ", ".join(actions[:-1]) + f" and {actions[-1]}"
                else:
                    action_str = actions[0]

                updated_last_line = f"{action_str} by {user_name} on {event_date}."
                engram_doc.summary = engram_doc.summary.replace(last_line, updated_last_line)
        else:
            # It's a new day or a new user, so we add a new line
            if event_name == "Emailed":
                summary_line = f"Emailed on {event_date}."
            else:
                summary_line = f"{event_name} by {user_name} on {event_date}."
            engram_doc.summary = (engram_doc.summary + "\n" + summary_line) if engram_doc.summary else summary_line

        # Update involved users
        involved = set(engram_doc.get("involved_users", "").split(", ") if engram_doc.get("involved_users") else [])
        involved.add(user_name)
        engram_doc.involved_users = ", ".join(sorted(list(filter(None, involved))))

        engram_doc.last_activity_date = doc.modified
        engram_doc.save(ignore_permissions=True)
        frappe.db.commit()

    except Exception:
        frappe.log_error(frappe.get_traceback(), f"Failed to update Engram for {doc.doctype} {doc.name}")
