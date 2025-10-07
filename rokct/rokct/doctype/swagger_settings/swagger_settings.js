// Copyright (c) 2024, ROKCT and contributors
// For license information, please see license.txt

frappe.ui.form.on("Swagger Settings", {
    refresh: function(frm) {
        // Clear previous messages and indicators
        frm.dashboard.clear_messages();
        frm.dashboard.clear_indicators();

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
                    const read_only_fields = ['last_generation_time', 'generation_status'];
                    frm.fields.forEach(function(field) {
                        if (field.df.fieldname !== 'generate_swagger_json' && !read_only_fields.includes(field.df.fieldname)) {
                           frm.set_df_property(field.df.fieldname, 'read_only', 0);
                        }
                    });
                    frm.enable_save();
                }
            }
        });
    },

    generate_swagger_json: function(frm) {
        frm.call('enqueue_swagger_generation').then(r => {
            if (r.message) {
                frappe.msgprint(r.message);
                frm.refresh(); // Refresh to show the "In Progress" status
            }
        })
    }
});