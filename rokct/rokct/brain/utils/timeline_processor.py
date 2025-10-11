# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.utils import getdate
from collections import defaultdict
from rokct.rokct.utils.subscription_checker import check_subscription_feature

@check_subscription_feature("Memory")
def process_event_log():
    """
    This function is a scheduled background job that processes raw events
    from the Synaptic Event log, compounds them into a human-readable Engram,
    and then deletes the processed events.
    """
    # Fetch all unprocessed events, limit to 500 to avoid timeouts
    events_to_process = frappe.get_all(
        "Synaptic Event",
        fields=["name", "reference_doctype", "reference_name", "event", "user", "creation"],
        limit=500,
        order_by="creation asc"
    )

    if not events_to_process:
        return

    # Group events by the document they refer to
    events_by_doc = defaultdict(list)
    for event in events_to_process:
        key = (event.reference_doctype, event.reference_name)
        events_by_doc[key].append(event)

    # Process each group of events
    for (doctype, name), events in events_by_doc.items():
        if not doctype or not name:
            continue

        # Get the existing engram or create a new one
        engram_name = f"{doctype}-{name}"
        try:
            engram_doc = frappe.get_doc("Engram", engram_name)
        except frappe.DoesNotExistError:
            engram_doc = frappe.new_doc("Engram")
            engram_doc.reference_doctype = doctype
            engram_doc.reference_name = name
            engram_doc.name = engram_name

        # --- Storytelling Engine ---
        # Group new events for this document by date and user
        events_by_date_user = defaultdict(lambda: defaultdict(list))
        for event in events:
            event_date = getdate(event.creation).strftime("%Y-%m-%d")
            events_by_date_user[event_date][event.user].append(event.event)

        # Generate new summary lines
        summary_lines = []
        all_users = set(engram_doc.get("involved_users", "").split(", ") if engram_doc.get("involved_users") else [])

        for date, user_events in sorted(events_by_date_user.items()):
            for user, event_types in user_events.items():
                all_users.add(user)

                actions = sorted(list(set([evt.replace("Document ", "") for evt in event_types])))

                email_summary = ""
                if "Email Sent" in actions:
                    actions.remove("Email Sent")
                    email_summary = "Emailed."

                if actions:
                    if len(actions) > 1:
                        action_str = ", ".join(actions[:-1]) + f" and {actions[-1]}"
                    else:
                        action_str = actions[0]

                    line = f"{action_str} by {user} on {date}."
                    if email_summary:
                        line = f"{line} {email_summary}"
                    summary_lines.append(line)
                elif email_summary:
                    summary_lines.append(f"Emailed on {date}.")

        # Update the engram document by appending the new summary
        new_summary = "\n".join(summary_lines)
        engram_doc.summary = (engram_doc.summary + "\n" + new_summary) if engram_doc.summary else new_summary
        engram_doc.involved_users = ", ".join(sorted(list(filter(None, all_users))))
        engram_doc.last_activity_date = events[-1].creation
        engram_doc.save(ignore_permissions=True)

    # --- Cleanup ---
    # Delete the events that have been successfully processed
    processed_event_names = [e.name for e in events_to_process]
    frappe.delete_doc("Synaptic Event", processed_event_names, ignore_permissions=True)

    frappe.db.commit()