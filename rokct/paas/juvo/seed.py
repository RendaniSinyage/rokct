import frappe
import os

def run_juvo_seed():
    """
    Executes the JUVO tenant-specific SQL seed script if the site matches.
    """
    if frappe.local.site == 'juvo.tenant.rokct.ai':
        sql_file_path = os.path.join(os.path.dirname(__file__), 'juvo_tenant_seed.sql')

        if not os.path.exists(sql_file_path):
            frappe.log_error(f"JUVO seed SQL file not found at: {sql_file_path}", "Seeding Error")
            return

        with open(sql_file_path, 'r') as f:
            sql_commands = f.read()

        for command in filter(None, sql_commands.split(';')):
            try:
                frappe.db.sql(command.strip())
            except Exception as e:
                frappe.log_error(f"Error executing JUVO seed SQL command: {command.strip()}", str(e))

        frappe.db.commit()
        print("JUVO tenant seed script executed successfully.")