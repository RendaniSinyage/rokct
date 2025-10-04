
frappe.ui.form.on('Roadmap', {
    features_on_form_rendered: function(frm) {
        // This function runs on initial load to set the button visibility for all rows.
        frm.fields_dict['features'].grid.grid_rows.forEach(function(row) {
            const button_wrapper = row.grid_form.fields_dict['assign_to_jules'].df.parent;
            if (row.doc.status === 'Idea Passed' || row.doc.status === 'Bugs') {
                $(button_wrapper).show();
            } else {
                $(button_wrapper).hide();
            }
        });
    }
});

frappe.ui.form.on('Roadmap Feature', {
    status: function(frm, cdt, cdn) {
        // This function runs when the status of a single row is changed.
        // It's more efficient as it targets only the row that was modified.
        let row_doc = locals[cdt][cdn];
        let grid_row = frm.fields_dict['features'].grid.grid_rows_by_docname[cdn];

        if (grid_row) {
            const button_wrapper = grid_row.grid_form.fields_dict['assign_to_jules'].df.parent;
            if (row_doc.status === 'Idea Passed' || row_doc.status === 'Bugs') {
                $(button_wrapper).show();
            } else {
                $(button_wrapper).hide();
            }
        }
    },
    assign_to_jules: function(frm, cdt, cdn) {
        let row = frappe.get_doc(cdt, cdn);

        frappe.confirm(
            `Are you sure you want to assign the task "${row.feature}" to Jules? <br><br><b>Disclaimer:</b> Jules can make mistakes so double-check it and use code with caution.`,
            () => {
                frappe.call({
                    method: 'rokct.roadmap.doctype.roadmap_feature.roadmap_feature.assign_to_jules',
                    args: {
                        docname: row.name,
                        feature: row.feature,
                        explanation: row.explanation
                    },
                    callback: function(r) {
                        if (r.message === "Success") {
                            frm.refresh_field('features');
                        }
                    },
                    freeze: true,
                    freeze_message: "Assigning task to Jules..."
                });
            }
        );
    }
});
