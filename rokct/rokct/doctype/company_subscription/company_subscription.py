# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document


class CompanySubscription(Document):
	def on_update(self):
		"""
		When a subscription's status changes, trigger specific actions.
		"""
		doc_before_save = self.get_doc_before_save()
		if not doc_before_save:
			return

		# If status is changed to 'Banned', enqueue a job to drop the site.
		if doc_before_save.status != "Banned" and self.status == "Banned":
			if self.site_name:
				frappe.enqueue(
					"rokct.rokct.control_panel.tasks.drop_tenant_site",
					queue="long",
					job_name=f"drop-site-{self.site_name}",
					site_name=self.site_name
				)
				frappe.msgprint(f"Site deletion for '{self.site_name}' has been scheduled.")

	def on_trash(self):
		"""
		Prevent deletion of subscriptions unless they are in a safe, non-active state.
		"""
		# Allow deletion only for subscriptions that are in a terminal or pre-setup state.
		allowed_to_delete_statuses = ["Setup Failed", "Provisioning", "Banned", "Dropped"]
		if self.status not in allowed_to_delete_statuses:
			frappe.throw(
				title="Deletion Not Allowed",
				msg=f"Cannot delete subscription '{self.name}' with status '{self.status}'. Only subscriptions with status 'Setup Failed', 'Provisioning', 'Banned', or 'Dropped' can be deleted."
			)

