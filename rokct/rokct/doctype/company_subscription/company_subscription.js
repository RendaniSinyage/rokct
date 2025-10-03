frappe.ui.form.on('Company Subscription', {
    refresh: function(frm) {
        if (frm.is_new()) {
            return;
        }

        // Button to resend the welcome email
        if (['Active', 'Trialing'].includes(frm.doc.status)) {
            frm.add_custom_button(__('Resend Welcome Email'), function() {
                frappe.call({
                    method: 'rokct.control_panel.api.resend_welcome_email',
                    args: { subscription_id: frm.doc.name },
                    callback: (r) => {
                        if (r.message) {
                            frappe.msgprint(r.message);
                        }
                    }
                });
            });
        }

        // Button to manually retry a failed payment
        if (frm.doc.status === 'Grace Period') {
            frm.add_custom_button(__('Retry Payment'), function() {
                frappe.call({
                    method: 'rokct.rokct.control_panel.billing.retry_billing_for_subscription',
                    args: {
                        subscription_name: frm.doc.name
                    },
                    callback: function(r) {
                        if (r.message) {
                            frappe.msgprint(r.message.message);
                        }
                    }
                });
            }).addClass('btn-primary');
        }
    }
});

