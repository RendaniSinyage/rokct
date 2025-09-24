#!/bin/bash

# Define API endpoint and email recipient
API_URL="https://api.juvo.app/api/v1/rest/status"
EMAIL="sinyage@gmail.com"
FROM_EMAIL="hello@juvo.app"

# Fetch the status from the API
response=$(curl -s $API_URL)

# Extract the status values using jq
food_app_status=$(echo $response | jq -r '.juvo_platform.food_app.status')
food_app_status_code=$(echo $response | jq -r '.juvo_platform.food_app.status_code')
main_website_status=$(echo $response | jq -r '.juvo_platform.main_website.status')
main_website_status_code=$(echo $response | jq -r '.juvo_platform.main_website.status_code')
admin_panel_status=$(echo $response | jq -r '.juvo_platform.admin_panel.status')
admin_panel_status_code=$(echo $response | jq -r '.juvo_platform.admin_panel.status_code')
agency_website_status=$(echo $response | jq -r '.juvo_platform.agency_website.status')
agency_website_status_code=$(echo $response | jq -r '.juvo_platform.agency_website.status_code')

# Check if any status is not "OK" or status_code is not 200
if [ "$food_app_status" != "OK" ] || [ "$food_app_status_code" -ne 200 ] ||
   [ "$main_website_status" != "OK" ] || [ "$main_website_status_code" -ne 200 ] ||
   [ "$admin_panel_status" != "OK" ] || [ "$admin_panel_status_code" -ne 200 ] ||
   [ "$agency_website_status" != "OK" ] || [ "$agency_website_status_code" -ne 200 ]; then

    # Prepare email content
    email_subject="API Status Alert"
    email_body="One or more API statuses are not OK. Please check the API endpoint for details."

    # Send an email notification
    {
        echo "From: $FROM_EMAIL"
        echo "To: $EMAIL"
        echo "Subject: $email_subject"
        echo
        echo "$email_body"
    } | sendmail -t
fi

