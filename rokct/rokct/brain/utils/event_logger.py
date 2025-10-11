# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
import json
from rokct.rokct.utils.subscription_checker import check_subscription_feature

@check_subscription_feature("Memory")
def cache_document_before_save(doc, method):
    """
    Caches a document's state before it's saved to compare for changes.
    """
    try:
        if doc.is_new():
            return
        original_doc = frappe.get_doc(doc.doctype, doc.name)
        frappe.local._before_save_doc = original_doc.as_dict()
    except Exception:
        frappe.local._before_save_doc = None
        frappe.log_error(frappe.get_traceback(), f"Failed to cache document for {doc.doctype} {doc.name}")

@check_subscription_feature("Memory")
def log_document_event(doc, method):
    """
    Creates a new record in the Synaptic Event log for any significant document change.
    """
    # --- Exclusion Logic ---
    ignored_doctypes = ["Synaptic Event", "Engram", "API Error Log", "Frontend Error Log"]
    if doc.doctype in ignored_doctypes:
        return

    try:
        module = frappe.db.get_value("DocType", doc.doctype, "module")
        ignored_modules = ["paas", "swagger", "brain"]
        if module in ignored_modules:
            return
    except Exception:
        pass

    try:
        event_name = f"Document {method.replace('on_', '').capitalize()}"
        source = frappe.local.request.headers.get("X-Event-Source") if hasattr(frappe.local, "request") else "Web Interface"

        data_to_log = {}
        if method == 'on_update' and hasattr(frappe.local, '_before_save_doc') and frappe.local._before_save_doc:
            original_doc = frappe.local._before_save_doc
            current_doc = doc.as_dict()
            changes = {
                key: {"old_value": original_doc.get(key), "new_value": value}
                for key, value in current_doc.items()
                if original_doc.get(key) != value
            }
            data_to_log = changes
            del frappe.local._before_save_doc
        else:
            data_to_log = doc.as_dict()

        frappe.get_doc({
            "doctype": "Synaptic Event",
            "event": event_name,
            "status": "Success",
            "source": source,
            "user": frappe.session.user,
            "reference_doctype": doc.doctype,
            "reference_name": doc.name,
            "data": json.dumps(data_to_log, indent=4, default=str)
        }).insert(ignore_permissions=True)
        frappe.db.commit()

    except Exception:
        frappe.log_error(frappe.get_traceback(), f"Failed to log document event for {doc.doctype} {doc.name}")

@check_subscription_feature("Memory")
def log_email_sent(doc, method):
    """
    Creates a new 'Email Sent' event in the Synaptic Event log.
    """
    try:
        if doc.status != "Sent":
            return

        frappe.get_doc({
            "doctype": "Synaptic Event",
            "event": "Email Sent",
            "status": "Success",
            "source": "System",
            "user": doc.owner,
            "reference_doctype": doc.reference_doctype,
            "reference_name": doc.reference_name,
            "data": json.dumps(doc.as_dict(), indent=4, default=str)
        }).insert(ignore_permissions=True)
        frappe.db.commit()

    except Exception:
        frappe.log_error(frappe.get_traceback(), f"Failed to log email sent event for {doc.reference_doctype} {doc.reference_name}")