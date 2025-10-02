import frappe
from frappe.tests.utils import FrappeTestCase
from unittest.mock import patch, MagicMock
from rokct.rokct.control_panel.tasks import manage_daily_subscriptions
from frappe.utils import nowdate, add_days

class TestDailySubscriptionManagement(FrappeTestCase):
    def setUp(self):
        # Create a default free plan for downgrades
        self.free_plan = frappe.get_doc({
            "doctype": "Subscription Plan",
            "plan_name": "Free Plan",
            "cost": 0
        }).insert(ignore_permissions=True)

        self.paid_plan = frappe.get_doc({
            "doctype": "Subscription Plan",
            "plan_name": "Paid Plan",
            "cost": 100,
            "trial_period_days": 7,
            "billing_cycle": "Month"
        }).insert(ignore_permissions=True)

        # Set the default free plan in settings
        frappe.db.set_value("Subscription Settings", "Subscription Settings", "default_free_plan", self.free_plan.name)
        frappe.db.set_value("Subscription Settings", "Subscription Settings", "grace_period_days", 5)

        # Create customers
        self.customer_with_card = frappe.get_doc({"doctype": "Customer", "customer_name": "Customer With Card", "stripe_customer_id": "cus_123"}).insert()
        self.customer_no_card = frappe.get_doc({"doctype": "Customer", "customer_name": "Customer No Card"}).insert()

        frappe.db.commit()

    def tearDown(self):
        frappe.db.rollback()

    def test_trial_converts_to_active_with_payment_method(self):
        # Arrange
        trial_sub = frappe.get_doc({
            "doctype": "Company Subscription", "customer": self.customer_with_card.name, "plan": self.paid_plan.name,
            "status": "Trialing", "trial_ends_on": nowdate()
        }).insert()

        # Act
        manage_daily_subscriptions()

        # Assert
        updated_sub = frappe.get_doc("Company Subscription", trial_sub.name)
        self.assertEqual(updated_sub.status, "Active")
        self.assertIsNone(updated_sub.trial_ends_on)
        self.assertEqual(updated_sub.next_billing_date, add_days(nowdate(), 30)) # Approximately, since add_months is used

    def test_trial_downgrades_without_payment_method(self):
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
        self.assertEqual(updated_sub.plan, self.free_plan.name)

    def test_active_sub_moves_to_grace_period_on_renewal_date(self):
        # Arrange
        active_sub = frappe.get_doc({
            "doctype": "Company Subscription", "customer": self.customer_with_card.name, "plan": self.paid_plan.name,
            "status": "Active", "next_billing_date": nowdate()
        }).insert()

        # Act
        manage_daily_subscriptions()

        # Assert
        updated_sub = frappe.get_doc("Company Subscription", active_sub.name)
        self.assertEqual(updated_sub.status, "Grace Period")

    def test_grace_period_sub_downgrades_after_5_days(self):
        # Arrange
        grace_sub = frappe.get_doc({
            "doctype": "Company Subscription", "customer": self.customer_with_card.name, "plan": self.paid_plan.name,
            "status": "Grace Period", "next_billing_date": add_days(nowdate(), -6)
        }).insert()

        # Act
        manage_daily_subscriptions()

        # Assert
        updated_sub = frappe.get_doc("Company Subscription", grace_sub.name)
        self.assertEqual(updated_sub.status, "Downgraded")
        self.assertEqual(updated_sub.plan, self.free_plan.name)

    def test_grace_period_sub_is_not_downgraded_before_5_days(self):
        # Arrange
        grace_sub = frappe.get_doc({
            "doctype": "Company Subscription", "customer": self.customer_with_card.name, "plan": self.paid_plan.name,
            "status": "Grace Period", "next_billing_date": add_days(nowdate(), -4)
        }).insert()

        # Act
        manage_daily_subscriptions()

        # Assert
        updated_sub = frappe.get_doc("Company Subscription", grace_sub.name)
        self.assertEqual(updated_sub.status, "Grace Period")