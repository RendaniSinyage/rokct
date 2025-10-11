# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document

class Engram(Document):
	pass

def get_permission_query_conditions(user):
    """
    Filters the list view of Engrams.
    Users can only see an Engram if they have read permission on the
    document that the Engram refers to.
    """
    if not user:
        user = frappe.session.user

    if "System Manager" in frappe.get_roles(user):
        # System Manager can see all Engram records
        return ""

    # This is the correct, secure way to filter based on document permissions.
    # It fetches a list of all documents the user is allowed to see and uses
    # that to filter the Engram list.

    # Get all unique doctypes present in the Engram table to check against
    engram_doctypes = frappe.get_all("Engram", fields=["distinct reference_doctype"], pluck="reference_doctype")

    allowed_docs = []
    for doctype in engram_doctypes:
        # For each doctype, get the list of documents the user can read.
        # `ignore_permissions=False` is the key here, it enforces all permission rules.
        try:
            allowed_names = frappe.get_list(doctype, fields=["name"], ignore_permissions=False, pluck="name")
            if allowed_names:
                for name in allowed_names:
                    # Create a tuple of (doctype, name) for the IN clause
                    allowed_docs.append(f"('{doctype}', '{name}')")
        except (frappe.PermissionError, frappe.DoesNotExistError):
            # Ignore if user has no access to the doctype itself
            pass

    if not allowed_docs:
        # If the user can't see any documents, they can't see any engrams
        return "`tabEngram`.`name` = 'UNMATCHED_DUE_TO_PERMISSIONS'"

    # Construct the final query
    return f"""
        (`tabEngram`.`reference_doctype`, `tabEngram`.`reference_name`) IN ({",".join(allowed_docs)})
    """


def has_permission(doc, ptype, user):
    """
    Checks if a user has permission to view a single Engram record.
    This is called when a user tries to open the form view directly.
    """
    if "System Manager" in frappe.get_roles(user):
        return True

    # Check if the user has read permission on the referenced document
    return frappe.has_permission(doc.reference_doctype, ptype="read", doc=doc.reference_name, user=user)