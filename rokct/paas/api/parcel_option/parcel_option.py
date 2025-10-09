import frappe

@frappe.whitelist(allow_guest=True)
def get_parcel_options():
    """
    Retrieves a list of all active Parcel Options.
    """
    try:
        options = frappe.get_list(
            "Parcel Option",
            filters={"active": 1},
            fields=["name", "title", "description", "price"],
            order_by="price asc"
        )
        return options
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "get_parcel_options Error")
        frappe.throw(f"An error occurred while fetching parcel options: {str(e)}")

# TODO: Implement create, update, and delete functions for admin management.