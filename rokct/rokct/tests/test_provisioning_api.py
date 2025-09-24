import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.control_panel.api import provision_new_tenant

class TestProvisioningAPI(FrappeTestCase):
    def setUp(self):
        frappe.conf.app_role = "control_panel"
        frappe.conf.tenant_domain = "test.saas.com"
        frappe.conf.bench_path = "/tmp/bench"

        # Mock doctypes that are looked up
        if not frappe.db.exists("Subscription Plan", "Test Plan"):
            frappe.get_doc({"doctype": "Subscription Plan", "plan_name": "Test Plan"}).insert()
        if not frappe.db.exists("Customer Group", "All Customer Groups"):
            frappe.get_doc({"doctype": "Customer Group", "customer_group_name": "All Customer Groups"}).insert()

    def tearDown(self):
        frappe.db.rollback()
        if hasattr(frappe.conf, "app_role"):
            del frappe.conf.app_role
        if hasattr(frappe.conf, "tenant_domain"):
            del frappe.conf.tenant_domain
        if hasattr(frappe.conf, "bench_path"):
            del frappe.conf.bench_path

    @patch("rokct.control_panel.api.subprocess.run")
    @patch("rokct.control_panel.api.frappe.enqueue")
    def test_provision_new_tenant_success(self, mock_enqueue, mock_subprocess_run):
        # Arrange
        mock_subprocess_run.return_value = MagicMock(check=True, returncode=0)

        test_data = {
            "plan": "Test Plan",
            "email": "test@example.com",
            "password": "password",
            "first_name": "Test",
            "last_name": "User",
            "company_name": "Test Company",
            "currency": "USD",
            "country": "USA",
            "industry": "IT"
        }

        # Act
        response = provision_new_tenant(**test_data)

        # Assert
        self.assertEqual(response["status"], "success")
        expected_site_name = "test-company.test.saas.com"
        self.assertEqual(response["site_name"], expected_site_name)

        # Assert that subprocess was called to create the site
        self.assertIn("new-site", mock_subprocess_run.call_args_list[0].args[0])
        self.assertIn(expected_site_name, mock_subprocess_run.call_args_list[0].args[0])

        # Assert that subprocess was called to set the config
        self.assertIn("set-config", mock_subprocess_run.call_args_list[1].args[0])
        self.assertIn("app_role", mock_subprocess_run.call_args_list[1].args[0])
        self.assertIn("tenant", mock_subprocess_run.call_args_list[1].args[0])

        # Assert that the background job was enqueued
        mock_enqueue.assert_called_once()
        self.assertEqual(mock_enqueue.call_args.args[0], "rokct.control_panel.tasks.complete_tenant_setup")
        self.assertEqual(mock_enqueue.call_args.kwargs["site_name"], expected_site_name)
        self.assertEqual(mock_enqueue.call_args.kwargs["user_details"]["email"], "test@example.com")

