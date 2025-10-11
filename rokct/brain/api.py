# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from rokct.brain import __version__ as brain_version

@frappe.whitelist()
def query(doctype, name):
    """
    A secure API endpoint for an AI model to query the Brain's memory.

    This function fetches the Engram (memory) for a specific document.
    It explicitly checks for read permission on the source document before
    returning any data, ensuring security is enforced.

    :param doctype: The DocType of the document to query.
    :param name: The name (ID) of the document to query.
    :return: A dictionary containing the Engram data.
    """
    # Explicitly check for read permission on the source document.
    # This is the crucial security step.
    if not frappe.has_permission(doctype, "read", doc=name):
        frappe.throw(f"You do not have permission to access the memory of {doctype} {name}", frappe.PermissionError)

    try:
        engram_name = f"{doctype}-{name}"
        engram_doc = frappe.get_doc("Engram", engram_name)
        response_data = engram_doc.as_dict()
        response_data['brain_version'] = brain_version
        return response_data
    except frappe.DoesNotExistError:
        frappe.throw(f"No Engram found for {doctype} {name}", frappe.NotFound)
    except Exception as e:
        frappe.throw(f"An error occurred while querying the Brain: {e}")


@frappe.whitelist()
def record_event(message, reference_doctype, reference_name):
    """
    A secure API endpoint for an AI model to record a custom event in the Brain's memory.
    This is used for events that fall outside the standard document lifecycle hooks,
    such as logging an action that failed.

    :param message: A string describing the event (e.g., "Action failed: Permission Denied").
    :param reference_doctype: The DocType of the document the event relates to.
    :param reference_name: The name (ID) of the document the event relates to.
    """
    try:
        # We need to create a mock object that has the necessary attributes
        # for the process_event_in_realtime function.
        class MockDoc:
            def __init__(self):
                self.doctype = reference_doctype
                self.name = reference_name
                self.modified = frappe.utils.now()
                self.owner = frappe.session.user

        mock_doc = MockDoc()

        # The 'method' parameter is used to build the event name,
        # so we can pass our custom message here.
        from rokct.brain.utils.engram_builder import process_event_in_realtime
        process_event_in_realtime(mock_doc, message)

        return {"status": "success", "message": "Event recorded."}
    except Exception as e:
        frappe.log_error(f"Brain: Failed to record event: {e}", frappe.get_traceback())
        frappe.throw(f"An error occurred while recording the event: {e}")


@frappe.whitelist()
def record_chat_summary(summary_text, reference_doctype=None, reference_name=None):
    """
    A secure API endpoint for the frontend to record a chat summary in the Brain's memory.

    :param summary_text: The AI-generated summary of the chat conversation.
    :param reference_doctype: (Optional) The DocType of a document to link the summary to.
    :param reference_name: (Optional) The name (ID) of a document to link the summary to.
    """
    if not summary_text or not isinstance(summary_text, str) or not summary_text.strip():
        frappe.throw("`summary_text` must be a non-empty string.", title="Invalid Input")

    try:
        # If no specific document is referenced, link the summary to the user who initiated the chat.
        if not reference_doctype or not reference_name:
            reference_doctype = "User"
            reference_name = frappe.session.user

        engram_name = f"{reference_doctype}-{reference_name}"

        # We don't use the standard engram_builder here because the summary is pre-generated.
        # We create a new Engram or append to an existing one for the same document.
        try:
            engram_doc = frappe.get_doc("Engram", engram_name)
        except frappe.DoesNotExistError:
            engram_doc = frappe.new_doc("Engram")
            engram_doc.reference_doctype = reference_doctype
            engram_doc.reference_name = reference_name
            engram_doc.name = engram_name
            # This utility function gets a user-friendly title for the reference doc
            from rokct.brain.utils.engram_builder import get_document_title
            engram_doc.reference_title = get_document_title(reference_doctype, reference_name)

        engram_doc.source = "Chat Summary"
        new_summary_line = f"Chat Summary by {frappe.get_doc('User', frappe.session.user).get_formatted('full_name')} on {frappe.utils.getdate(frappe.utils.now())}:\n{summary_text}"

        engram_doc.summary = (engram_doc.summary + "\n\n---\n\n" + new_summary_line) if engram_doc.summary else new_summary_line

        # Update involved users
        involved = set(engram_doc.get("involved_users", "").split(", ") if engram_doc.get("involved_users") else [])
        involved.add(frappe.get_doc('User', frappe.session.user).get_formatted('full_name'))
        engram_doc.involved_users = ", ".join(sorted(list(filter(None, involved))))

        engram_doc.last_activity_date = frappe.utils.now()
        engram_doc.save(ignore_permissions=True)
        frappe.db.commit()

        return {"status": "success", "message": f"Chat summary recorded in Engram {engram_doc.name}."}

    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(f"Brain: Failed to record chat summary: {e}", frappe.get_traceback())
        frappe.throw(f"An error occurred while recording the chat summary: {e}")