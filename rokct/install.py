import frappe

def before_install():
    """
    This function is called before the app is installed.
    """
    print("--- Starting ROKCT App Installation ---")
    frappe.msgprint("--- Starting ROKCT App Installation ---")

def after_install():
    """
    This function is called after the app is installed.
    """
    print("--- ROKCT App Installation Complete ---")
    frappe.msgprint("--- ROKCT App Installation Complete ---")