frappe.listview_settings['Roadmap'] = {
    onload: function(listview) {
        // Get the names of all the roadmaps currently in the list view
        const roadmap_names = listview.data.map(doc => doc.name);

        if (roadmap_names.length === 0) {
            return;
        }

        // Call the backend API to get the statuses for these roadmaps
        frappe.call({
            method: 'rokct.roadmap.api.get_roadmap_statuses',
            args: {
                roadmap_names: JSON.stringify(roadmap_names)
            },
            callback: function(r) {
                if (r.message) {
                    const statuses = r.message;

                    // Iterate through the documents and add the status indicators
                    listview.data.forEach(doc => {
                        const status_info = statuses[doc.name];
                        if (status_info) {
                            const row = listview.wrapper.find('.list-row-container[data-name="' + doc.name + '"]');

                            // Clear existing custom indicators to prevent duplication on refresh
                            row.find('.custom-list-indicators').remove();

                            let indicators_html = '<div class="custom-list-indicators" style="display: inline-flex; gap: 5px; margin-left: 10px; vertical-align: middle;">';

                            if (status_info.is_linked) {
                                indicators_html += '<span class="indicator-pill green"><span>GitHub Linked</span></span>';
                            }
                            if (status_info.ai_ready) {
                                indicators_html += '<span class="indicator-pill blue"><span>AI Ready</span></span>';
                            }

                            indicators_html += '</div>';

                            // Append the indicators to the title area for better visibility
                            row.find('.list-subject').append(indicators_html);
                        }
                    });
                }
            }
        });
    }
};