import frappe
import os

def run_juvo_seed():
    """
    Executes the JUVO tenant-specific SQL seed script if the site matches.
    """
    # Check if the current site is the intended target
    if frappe.local.site == 'juvo.tenant.rokct.ai':
        # Construct the absolute path to the SQL file
        sql_file_path = os.path.join(os.path.dirname(__file__), 'juvo_tenant_seed.sql')

        # Verify that the SQL file exists before attempting to read it
        if not os.path.exists(sql_file_path):
            frappe.log_error(f"JUVO seed SQL file not found at: {sql_file_path}", "seeding Error")
            return

        # Read the SQL commands from the file
        with open(sql_file_path, 'r') as f:
            sql_commands = f.read()

        # Execute each SQL command individually
        # The SQL file might contain multiple statements that need to be run separately.
        # We split the script by semicolons and filter out any empty strings.
        for command in filter(None, sql_commands.split(';')):
            try:
                frappe.db.sql(command.strip())
            except Exception as e:
                # Log any errors that occur during SQL execution
                frappe.log_error(f"Error executing JUVO seed SQL command: {command.strip()}", str(e))

        # Commit the changes to the database
        frappe.db.commit()
        print("JUVO tenant seed script executed successfully.")