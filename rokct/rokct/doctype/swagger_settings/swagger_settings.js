// Copyright (c) 2024, ROKCT and contributors
// For license information, please see license.txt

frappe.ui.form.on("Swagger Settings", {
    refresh: function(frm) {
        // Clear previous messages and indicators
        frm.dashboard.clear_messages();
        frm.dashboard.clear_indicators();

        // Remove existing custom buttons to prevent duplicates on refresh
        if(frm.custom_buttons["View Log"]) {
            frm.remove_custom_button("View Log");
        }

        // Show the generation status
        if (frm.doc.generation_status) {
            let color = {
                "Success": "green",
                "Failed": "red",
                "In Progress": "blue"
            }[frm.doc.generation_status];

            frm.dashboard.add_indicator(
                __('Generation Status: {0}', [frm.doc.generation_status]) +
                (frm.doc.last_generation_time ? ` (${frappe.datetime.comment_when(frm.doc.last_generation_time)})` : ''),
                color
            );

            // Add "View Log" button if there is a log to show
            if (frm.doc.generation_log) {
                frm.add_custom_button(__('View Log'), function() {
                    frappe.msgprint({
                        title: __('Generation Log'),
                        indicator: frm.doc.generation_status === 'Failed' ? 'red' : 'blue',
                        message: `<pre style="white-space: pre-wrap; word-wrap: break-word;">${frm.doc.generation_log}</pre>`
                    });
                });
            }
        } else {
            frm.dashboard.add_indicator(__('Status not available. Generate documentation to see the status.'), 'gray');
        }

        frappe.call({
            method: "rokct.rokct.doctype.swagger_settings.swagger_settings.get_app_role",
            callback: function(r) {
                const is_control_panel = r.message && r.message === 'control_panel';

                // Toggle visibility of the generate button
                frm.get_field('generate_swagger_json').toggle(is_control_panel);

                if (!is_control_panel) {
                    // If not the control site, make everything read-only
                    frm.dashboard.add_warning_message(
                        __('Swagger settings can only be managed on the control site. This site has the role: <b>{0}</b>. All fields are read-only.', [r.message || 'tenant'])
                    );

                    frm.fields.forEach(function(field) {
                        frm.set_df_property(field.df.fieldname, 'read_only', 1);
                    });
                    frm.disable_save();
                } else {
                    // If it is the control site, ensure fields are writable
                    // Keep status fields read-only
                    const read_only_fields = ['last_generation_time', 'generation_status', 'generation_log'];
                    frm.fields.forEach(function(field) {
                        if (field.df.fieldname !== 'generate_swagger_json' && !read_only_fields.includes(field.df.fieldname)) {
                           frm.set_df_property(field.df.fieldname, 'read_only', 0);
                        }
                    });
                    frm.enable_save();

                    // Dynamically set options for the original_name field in the app_renaming_rules table
                    frappe.call({
                        method: "rokct.rokct.doctype.swagger_settings.swagger_settings.get_installed_apps_list",
                        callback: function(res) {
                            if (res.message) {
                                let field = frappe.meta.get_docfield("Swagger App Rename", "original_name", frm.doc.name);
                                field.options = res.message.join("\n");
                                frm.refresh_field("app_renaming_rules");
                            }
                        }
                    });
                }
            }
        });
    },

    refresh_app_list: function(frm) {
        frappe.call({
            method: "rokct.rokct.doctype.swagger_settings.swagger_settings.cache_installed_apps",
            callback: function(r) {
                if (r.message) {
                    // Update the options for the 'original_name' field in the child table
                    let field = frappe.meta.get_docfield("Swagger App Rename", "original_name", frm.doc.name);
                    field.options = r.message.join("\n");
                    frm.refresh_field("app_renaming_rules");

                    frappe.show_alert({
                        message: __("App list has been refreshed successfully."),
                        indicator: 'green'
                    }, 5);
                } else {
                    frappe.show_alert({
                        message: __("Failed to refresh app list."),
                        indicator: 'red'
                    }, 5);
                }
            }
        });
    },

    generate_swagger_json: function(frm) {
        frappe.call({
            method: "rokct.rokct.doctype.swagger_settings.swagger_settings.enqueue_swagger_generation",
            callback: function(r) {
                if (r.message) {
                    frappe.msgprint(r.message);
                    frm.refresh(); // Refresh to show the "In Progress" status
                }
            }
        });
    }
});