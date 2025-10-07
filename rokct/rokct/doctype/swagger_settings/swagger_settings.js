// Copyright (c) 2024, ROKCT and contributors
// For license information, please see license.txt

frappe.ui.form.on("Swagger Settings", {
    refresh: function(frm) {
        // Clear previous messages to avoid duplicates
        frm.dashboard.clear_messages();

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
                    frm.fields.forEach(function(field) {
                        // We don't want to make the button writable
                        if (field.df.fieldname !== 'generate_swagger_json') {
                           frm.set_df_property(field.df.fieldname, 'read_only', 0);
                        }
                    });
                    frm.enable_save();
                }
            }
        });
    },

    generate_swagger_json: function(frm) {
        frappe.call({
            method: "rokct.swagger.swagger_generator.generate_swagger_json",
            callback: function() {
                frappe.msgprint(__('Swagger generation job has been enqueued.'));
            }
        });
    }
});