import frappe
from rokct.rokct.control_panel.tasks import hello_world_job

def run_manual_creation():
    """
    Manually triggers the 'hello_world_job' for diagnostic purposes.
    """
    print("--- Starting Manual Worker Test ---")
    print("This will enqueue a minimal 'Hello World' job.")
    print("After running, please check for the file 'logs/test_worker.log'.")

    try:
        frappe.enqueue(
            "rokct.control_panel.tasks.hello_world_job",
            queue="long"
        )
        print("\nSUCCESS: 'hello_world_job' has been enqueued.")
        print("Please check the worker logs and the 'test_worker.log' file in a moment.")
    except Exception as e:
        print(f"\n--- FATAL ERROR: Failed to enqueue the job. ---")
        print(f"Reason: {e}")
        frappe.log_error(frappe.get_traceback(), "Manual Test Enqueue Failure")