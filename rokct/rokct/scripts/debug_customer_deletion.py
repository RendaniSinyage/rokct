import frappe

@frappe.whitelist()
def trigger_customer_deletion_for_debug(customer_name):
    """
    A debug utility to run the full customer deletion cascade synchronously
    and see the output directly in the terminal.
    """
    print("--- Starting Debug Customer Deletion ---")
    print(f"Target customer: {customer_name}")

    if not customer_name:
        print("!!! ERROR: Please provide a customer_name to delete.")
        return

    # 1. Find the customer
    if not frappe.db.exists("Customer", customer_name):
        print(f"!!! ERROR: Customer '{customer_name}' not found.")
        return

    print(f"Found customer '{customer_name}'.")

    # 2. Delete the customer document
    try:
        # This will trigger the 'on_trash' hook for the Customer doctype.
        print("Deleting customer document to trigger 'on_trash' hook...")
        frappe.delete_doc("Customer", customer_name, force=True, ignore_permissions=True)
        frappe.db.commit()
        print("Customer deletion command executed. The 'on_trash' hook should have run and triggered the full cascade.")
        print("--- Debug Customer Deletion Script Finished ---")

    except Exception as e:
        print(f"!!! AN ERROR OCCURRED during customer deletion !!!")
        print(frappe.get_traceback())
        frappe.log_error(frappe.get_traceback(), "Debug Customer Deletion Failed")
        return