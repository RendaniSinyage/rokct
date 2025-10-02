import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.rokct.control_panel.api import provision_new_tenant
from rokct.rokct.control_panel.tasks import drop_tenant_site
import os

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
        self.assertEqual(mock_enqueue.call_args.args[0], "rokct.rokct.control_panel.tasks.create_tenant_site_job")
        self.assertEqual(mock_enqueue.call_args.kwargs["site_name"], "tc.test.saas.com")
        self.assertEqual(mock_enqueue.call_args.kwargs["user_details"]["email"], "test@example.com")

    def test_provision_new_tenant_returns_alert_if_subscription_exists(self):
        # Arrange: Create an existing customer and subscription
        customer = frappe.get_doc({
            "doctype": "Customer",
            "customer_name": "Existing Corp",
            "customer_group": "All Customer Groups",
            "default_currency": "USD"
        }).insert(ignore_permissions=True)

        frappe.get_doc({
            "doctype": "Company Subscription",
            "customer": customer.name,
            "plan": "Test Plan",
            "status": "Active",
            "site_name": "existing.test.saas.com"
        }).insert(ignore_permissions=True)
        frappe.db.commit()

        test_data = {
            "plan": "Test Plan",
            "email": "anotheruser@example.com",
            "password": "password123",
            "first_name": "Another",
            "last_name": "User",
            "company_name": "Existing Corp",  # Same company name
            "currency": "USD",
            "country": "USA",
            "industry": "Retail"
        }

        # Act
        response = provision_new_tenant(**test_data)

        # Assert
        self.assertEqual(response["status"], "failed")
        self.assertIn("alert", response)
        self.assertEqual(response["alert"]["title"], "Existing Subscription Found")
        self.assertIn("A subscription for 'Existing Corp' already exists.", response["alert"]["message"])

    def test_provision_new_tenant_returns_alert_on_site_name_conflict(self):
        # Arrange: Create a subscription that will cause a site name conflict
        customer = frappe.get_doc({
            "doctype": "Customer",
            "customer_name": "Conflict Inc.",
            "customer_group": "All Customer Groups",
            "default_currency": "USD"
        }).insert(ignore_permissions=True)

        frappe.get_doc({
            "doctype": "Company Subscription",
            "customer": customer.name,
            "plan": "Test Plan",
            "status": "Active",
            "site_name": "ci.test.saas.com"  # This will conflict with "C.I."
        }).insert(ignore_permissions=True)
        frappe.db.commit()

        test_data = {
            "plan": "Test Plan",
            "email": "user@ci.com",
            "password": "password123",
            "first_name": "Test",
            "last_name": "User",
            "company_name": "C.I.",  # Different company name, but generates same site name
            "currency": "USD",
            "country": "USA",
            "industry": "Tech"
        }

        # Act
        response = provision_new_tenant(**test_data)

        # Assert
        self.assertEqual(response["status"], "failed")
        self.assertIn("alert", response)
        self.assertEqual(response["alert"]["title"], "Site Name Conflict")
        self.assertIn("The generated site name 'ci.test.saas.com' is already in use by 'Conflict Inc.'.", response["alert"]["message"])


class TestSiteDeletion(FrappeTestCase):
    def setUp(self):
        frappe.conf.bench_path = "/tmp/bench"
        self.customer = frappe.get_doc({
            "doctype": "Customer",
            "customer_name": "Test Customer for Deletion",
            "customer_group": "All Customer Groups",
        }).insert(ignore_permissions=True)

        self.subscription = frappe.get_doc({
            "doctype": "Company Subscription",
            "customer": self.customer.name,
            "plan": "Test Plan",
            "status": "Canceled",
            "site_name": "delete-me.test.saas.com"
        }).insert(ignore_permissions=True)
        frappe.db.commit()

    def tearDown(self):
        frappe.db.rollback()
        if hasattr(frappe.conf, "bench_path"):
            del frappe.conf.bench_path

    @patch("rokct.rokct.control_panel.tasks.subprocess.run")
    @patch("rokct.rokct.control_panel.tasks.os.path.exists")
    def test_drop_site_updates_subscription_status(self, mock_path_exists, mock_subprocess_run):
        # Arrange
        # 1. Mock the site existing before the call, and not existing after.
        mock_path_exists.side_effect = [True, False]
        # 2. Mock a successful subprocess run for `bench drop-site`
        mock_subprocess_run.return_value = MagicMock(check=True, returncode=0, stdout="", stderr="")

        # Act
        drop_tenant_site(self.subscription.site_name)

        # Assert
        # 1. Check if the subscription status was updated
        updated_subscription = frappe.get_doc("Company Subscription", self.subscription.name)
        self.assertEqual(updated_subscription.status, "Dropped")

        # 2. Verify that the mocks were called as expected
        self.assertEqual(mock_path_exists.call_count, 2)
        mock_subprocess_run.assert_called_once()
        self.assertIn("drop-site", mock_subprocess_run.call_args.args[0])
        self.assertIn(self.subscription.site_name, mock_subprocess_run.call_args.args[0])
