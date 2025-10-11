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