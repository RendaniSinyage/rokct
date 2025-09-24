frappe.listview_settings['Company Subscription'] = {
    refresh: function(listview) {
        // Add a custom button to the list view for approving migrations
        listview.page.add_inner_button(__('Approve Migration'), function() {
            const checked_items = listview.get_checked_items(true);
            if (checked_items.length === 0) {
                frappe.msgprint(__('Please select at least one subscription to approve.'));
                return;
            }

            // Approve all selected subscriptions
            checked_items.forEach(subscription_id => {
                frappe.call({
                    method: 'rokct.rokct.control_panel.api.approve_migration',
                    args: {
                        subscription_id: subscription_id
                    },
                    callback: function(r) {
                        if (r.message) {
                            frappe.show_alert(r.message);
                        }
                    }
                });
            });

            // Refresh the list view after a short delay to allow all API calls to complete
            setTimeout(() => {
                listview.refresh();
            }, 1000);

        }).addClass('btn-primary');
    },

    get_indicator: function(doc) {
        // Add a visual indicator for PaaS plans awaiting migration approval
        if (doc.paas_plan && !doc.migration_approved) {
            return [__("Awaiting Approval"), "orange", "paas_plan,=,1,and,migration_approved,=,0"];
        } else if (doc.paas_plan && doc.migration_approved) {
            return [__("Approved"), "green", "migration_approved,=,1"];
        }
    }
};

