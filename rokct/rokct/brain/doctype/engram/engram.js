// Copyright (c) 2025 ROKCT Holdings
// For license information, please see license.txt

frappe.ui.form.on("Engram", {
	refresh: function(frm) {
        // --- "Me" Personalization ---
        // This script takes the raw summary text, replaces the current user's
        // full name with "me", and then renders it in a custom HTML field.
        // This provides a personalized experience without altering the original data.
        if (frm.doc.summary) {
            let current_user_full_name = frappe.user.full_name;
            // Use a regex with word boundaries to avoid replacing parts of names
            let personalized_summary = frm.doc.summary.replace(new RegExp(`\\b${current_user_full_name}\\b`, "g"), "me");

            // Format the summary for better readability
            let formatted_summary = `<div style="font-family: monospace; white-space: pre-wrap;">${personalized_summary}</div>`;

            // Set the content of the custom HTML field
            frm.get_field("summary_display").$wrapper.html(formatted_summary);
        }
	}
});