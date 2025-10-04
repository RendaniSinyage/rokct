
frappe.ui.form.on('Roadmap Feature', {
    assign_to_jules: function(frm, cdt, cdn) {
        let row = frappe.get_doc(cdt, cdn);

        // Show a confirmation dialog before proceeding
        frappe.confirm(
            `Are you sure you want to assign the task "${row.feature}" to Jules?`,
            () => {
                // Proceed if the user confirms
                frappe.call({
                    method: 'rokct.roadmap.doctype.roadmap_feature.roadmap_feature.assign_to_jules',
                    args: {
                        docname: row.name,
                        feature: row.feature,
                        explanation: row.explanation
                    },
                    callback: function(r) {
                        if (r.message === "Success") {
                            // The server-side method already shows a confirmation message.
                            // We just need to refresh the child table to show the updated AI Status.
                            frm.refresh_field('features');
                        }
                        // Errors are handled by frappe.throw on the server side, which shows a dialog.
                    },
                    freeze: true,
                    freeze_message: "Assigning task to Jules..."
                });
            }
        );
    }
});
