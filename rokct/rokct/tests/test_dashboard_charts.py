import frappe
from frappe.tests.utils import FrappeTestCase
from rokct.control_panel.dashboard_charts import get_new_subscriptions_chart_data
from frappe.utils import nowdate, add_days

class TestDashboardCharts(FrappeTestCase):
    def setUp(self):
        # Set the app_role for the test site
        frappe.conf.app_role = "control_panel"

        # Create some test subscriptions
        self._create_test_subscription(days_ago=1)
        self._create_test_subscription(days_ago=1)
        self._create_test_subscription(days_ago=5)
        self._create_test_subscription(days_ago=25)

    def tearDown(self):
        # Clean up created documents
        frappe.db.rollback()
        # Reset app_role
        if hasattr(frappe.conf, "app_role"):
            del frappe.conf.app_role

    def _create_test_subscription(self, days_ago):
        sub = frappe.get_doc({
            "doctype": "Company Subscription",
            "customer": self._get_test_customer(),
            "plan": self._get_test_plan(),
            "status": "Active"
        })
        sub.creation = add_days(nowdate(), -days_ago)
        sub.insert()

    def _get_test_customer(self):
        if not frappe.db.exists("Customer", "Test Customer"):
            frappe.get_doc({
                "doctype": "Customer",
                "customer_name": "Test Customer",
                "customer_group": "All Customer Groups"
            }).insert()
        return "Test Customer"

    def _get_test_plan(self):
        if not frappe.db.exists("Subscription Plan", "Test Plan"):
            frappe.get_doc({
                "doctype": "Subscription Plan",
                "plan_name": "Test Plan"
            }).insert()
        return "Test Plan"

    def test_get_new_subscriptions_chart_data(self):
        # Call the function to be tested
        chart_data = get_new_subscriptions_chart_data()

        # Assertions
        self.assertIn("labels", chart_data)
        self.assertIn("datasets", chart_data)
        self.assertEqual(len(chart_data["labels"]), 30)
        self.assertEqual(len(chart_data["datasets"]), 1)
        self.assertEqual(len(chart_data["datasets"][0]["values"]), 30)

        # Check the values for the specific days we created data for
        # The labels are from 29 days ago to today.
        # So, today is index 29, yesterday is 28, etc.
        values = chart_data["datasets"][0]["values"]

        # 2 subscriptions created 1 day ago
        self.assertEqual(values[28], 2)
        # 1 subscription created 5 days ago
        self.assertEqual(values[24], 1)
        # 1 subscription created 25 days ago
        self.assertEqual(values[4], 1)
        # 0 subscriptions created today
        self.assertEqual(values[29], 0)

