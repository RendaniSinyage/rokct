frappe.ui.form.on('Flutter App Configuration', {
    refresh: function(frm) {
        // This function runs when the form is loaded or refreshed
        frm.trigger('update_build_target_options');
        frm.trigger('fetch_base_version');

        if (frm.is_new()) {
            return;
        }

        // Add a custom button to the form's header
        frm.add_custom_button(__('Generate Build'), function() {
            frappe.show_alert({
                message: __('Starting build. This may take several minutes. You can monitor the progress in the Build Log section below.'),
                indicator: 'blue'
            });

            frappe.call({
                method: 'rokct.rokct.flutter_builder.tasks.generate_flutter_app',
                args: {
                    app_config_name: frm.doc.name
                },
                callback: function(r) {
                    frappe.show_alert({
                        message: __('Build job has been started in the background.'),
                        indicator: 'green'
                    });
                    frm.reload_doc();
                },
                error: function(r) {
                    frappe.show_alert({
                        message: __('Failed to start the build job. Please check the Error Log.'),
                        indicator: 'red'
                    });
                }
            });
        }).addClass('btn-primary');

        // Setup real-time event listener
        frappe.realtime.on('flutter_build_complete', function(data) {
            // Check if the notification is for the current document
            if (data.app_config_name === frm.doc.name) {
                if (data.status === 'Success') {
                    frappe.show_alert({
                        message: __('Build completed successfully!'),
                        indicator: 'green'
                    });
                } else {
                    frappe.show_alert({
                        message: __('Build failed. Check the Build Log for details.'),
                        indicator: 'red'
                    });
                }
                // Refresh the form to show the final status and download link
                frm.reload_doc();
            }
        });
    },

    source_project: function(frm) {
        frm.trigger('update_build_target_options');
        frm.trigger('fetch_base_version');
    },

    fetch_base_version: function(frm) {
        if (frm.doc.source_project) {
            frappe.call({
                method: 'rokct.rokct.flutter_builder.tasks.get_project_version',
                args: {
                    source_project: frm.doc.source_project
                },
                callback: function(r) {
                    if (r.message) {
                        frm.set_value('base_version', r.message);
                    }
                }
            });
        }
    },

    update_build_target_options: function(frm) {
        let source_project = frm.doc.source_project;
        let options = [];

        if (source_project === 'pos') {
            options = ['Android APK', 'Android AAB', 'Windows EXE'];
        } else {
            options = ['Android APK', 'Android AAB'];
        }

        frm.set_df_property('build_target', 'options', options.join('\n'));
        // Set a default value if the current one is not in the new list
        if (!options.includes(frm.doc.build_target)) {
            frm.set_value('build_target', options[0]);
        }
    }
});

