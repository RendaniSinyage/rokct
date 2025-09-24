frappe.ui.form.on('Company Subscription', {
    refresh: function(frm) {
        if (['Active', 'Trialing'].includes(frm.doc.status) && !frm.is_new()) {
            frm.add_custom_button(__('Resend Welcome Email'), function() {
                frappe.call({
                    method: 'rokct.control_panel.api.resend_welcome_email',
                    args: {
                        subscription_id: frm.doc.name
                    },
                    callback: function(r) {
                        if (r.message) {
                            frappe.msgprint(r.message);
                        }
                    }
                });
            }).addClass('btn-primary');
        }
    }
});

