import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.rokct.control_panel.tasks import manage_daily_subscriptions, drop_tenant_site, cleanup_unverified_tenants
from frappe.utils import nowdate, add_days
import os

class TestDailySubscriptionManagement(FrappeTestCase):
    def setUp(self):
        # Create a Free-Monthly plan for downgrades
        self.free_plan = frappe.get_doc({
            "doctype": "Subscription Plan",
            "plan_name": "Free-Monthly",
            "cost": 0
        }).insert(ignore_permissions=True)

        self.paid_plan = frappe.get_doc({
            "doctype": "Subscription Plan",
            "plan_name": "Paid Plan",
            "cost": 100,
            "trial_period_days": 7,
            "billing_cycle": "Month"
        }).insert(ignore_permissions=True)

        # Set the grace period in settings
        frappe.db.set_value("Subscription Settings", "Subscription Settings", "grace_period_days", 5)

        # Create customers
        self.customer_no_card = frappe.get_doc({"doctype": "Customer", "customer_name": "Customer No Card"}).insert()

        frappe.db.commit()

    def tearDown(self):
        frappe.db.rollback()

    def test_trial_downgrades_to_free_monthly_and_saves_previous_plan(self):
        # Arrange
        trial_sub = frappe.get_doc({
            "doctype": "Company Subscription", "customer": self.customer_no_card.name, "plan": self.paid_plan.name,
            "status": "Trialing", "trial_ends_on": add_days(nowdate(), -1)
        }).insert()

        # Act
        manage_daily_subscriptions()

        # Assert
        updated_sub = frappe.get_doc("Company Subscription", trial_sub.name)
        self.assertEqual(updated_sub.status, "Downgraded")
        self.assertEqual(updated_sub.plan, "Free-Monthly")
        self.assertEqual(updated_sub.previous_plan, self.paid_plan.name)

    def test_grace_period_downgrades_to_free_monthly_and_saves_previous_plan(self):
        # Arrange
        grace_sub = frappe.get_doc({
            "doctype": "Company Subscription", "customer": self.customer_no_card.name, "plan": self.paid_plan.name,
            "status": "Grace Period", "next_billing_date": add_days(nowdate(), -6)
        }).insert()

        # Act
        manage_daily_subscriptions()

        # Assert
        updated_sub = frappe.get_doc("Company Subscription", grace_sub.name)
        self.assertEqual(updated_sub.status, "Downgraded")
        self.assertEqual(updated_sub.plan, "Free-Monthly")
        self.assertEqual(updated_sub.previous_plan, self.paid_plan.name)


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
            "plan": "Paid Plan",
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
        mock_path_exists.side_effect = [True, False]
        mock_subprocess_run.return_value = MagicMock(check=True, returncode=0, stdout="", stderr="")

        # Act
        drop_tenant_site(self.subscription.site_name)

        # Assert
        updated_subscription = frappe.get_doc("Company Subscription", self.subscription.name)
        self.assertEqual(updated_subscription.status, "Dropped")
        self.assertEqual(mock_path_exists.call_count, 2)
        mock_subprocess_run.assert_called_once()
        self.assertIn("drop-site", mock_subprocess_run.call_args.args[0])
        self.assertIn(self.subscription.site_name, mock_subprocess_run.call_args.args[0])


class TestUnverifiedTenantCleanup(FrappeTestCase):
    def setUp(self):
        self.sub_to_cancel = frappe.get_doc({
            "doctype": "Company Subscription", "customer": "Test Customer 1", "plan": "Paid Plan",
            "status": "Active", "site_name": "cancel-me.test.saas.com",
            "subscription_start_date": add_days(nowdate(), -5), "email_verified_on": None
        }).insert(ignore_permissions=True)

        self.sub_to_ignore_verified = frappe.get_doc({
            "doctype": "Company Subscription", "customer": "Test Customer 2", "plan": "Paid Plan",
            "status": "Active", "site_name": "ignore-me-verified.test.saas.com",
            "subscription_start_date": add_days(nowdate(), -5), "email_verified_on": nowdate()
        }).insert(ignore_permissions=True)

        frappe.db.commit()

    def tearDown(self):
        frappe.db.rollback()

    @patch("rokct.rokct.control_panel.tasks.frappe.log")
    def test_cleanup_cancels_only_old_unverified_subscriptions(self, mock_log):
        # Act
        cleanup_unverified_tenants()

        # Assert
        self.assertEqual(frappe.db.get_value("Company Subscription", self.sub_to_cancel.name, "status"), "Canceled")
        self.assertEqual(frappe.db.get_value("Company Subscription", self.sub_to_ignore_verified.name, "status"), "Active")
        mock_log.assert_any_call(f"Found 1 unverified subscriptions to cancel.")
        mock_log.assert_any_call(f"Canceled subscription {self.sub_to_cancel.name} for customer 'Test Customer 1' (Site: cancel-me.test.saas.com) due to missing email verification. Start date: {add_days(nowdate(), -5)}.", title="Subscription Canceled (No Verification)")