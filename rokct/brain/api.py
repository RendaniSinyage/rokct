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