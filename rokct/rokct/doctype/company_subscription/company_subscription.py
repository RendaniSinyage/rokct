# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt

import frappe
from frappe.model.document import Document


class CompanySubscription(Document):
	def on_update(self):
		"""
		When a subscription's status changes, trigger actions based on the new status.
		"""
		if self.get_doc_before_save() and self.get_doc_before_save().status != "Cancelled" and self.status == "Cancelled":
			self.enqueue_site_deletion()

	def enqueue_site_deletion(self):
		"""
		Enqueues a background job to drop the tenant's site.
		"""
		if not self.site_name:
			frappe.log_error(
				title="Missing Site Name",
				message=f"Could not enqueue site deletion for subscription {self.name} because the site name is missing."
			)
			return

		frappe.enqueue(
			"rokct.rokct.control_panel.tasks.drop_tenant_site",
			queue="long",
			timeout=600,
			site_name=self.site_name
		)
		frappe.msgprint(frappe._("Site deletion for {0} has been scheduled.").format(self.site_name), alert=True)