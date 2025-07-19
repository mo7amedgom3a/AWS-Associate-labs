#!/bin/bash

# Script to test S3 static website
# Author: mo7amedgom3a
# Date: July 19, 2025

echo "=== S3 Static Website Test Script ==="

# Get bucket name from saved file or user input
if [ -f .bucket_name ] && [ -f .bucket_region ]; then
    BUCKET_NAME=$(cat .bucket_name)
    REGION=$(cat .bucket_region)
    echo "Found saved deployment: Bucket=$BUCKET_NAME, Region=$REGION"
else
    echo "No saved deployment found."
    read -p "Enter bucket name to test: " BUCKET_NAME
    read -p "Enter region: " REGION
fi

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: No bucket name provided."
    exit 1
fi

# Construct website URL
WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"

echo "Testing website availability at: $WEBSITE_URL"

# Test if website is accessible using curl
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_URL")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "SUCCESS: Website is accessible (HTTP Status: $HTTP_STATUS)"
    echo "Website URL: $WEBSITE_URL"
    
    # Optional: Open in browser if running in GUI environment
    if command -v xdg-open &> /dev/null; then
        read -p "Open website in browser? (y/n): " OPEN_BROWSER
        if [ "$OPEN_BROWSER" = "y" ] || [ "$OPEN_BROWSER" = "Y" ]; then
            xdg-open "$WEBSITE_URL"
        fi
    fi
else
    echo "ERROR: Website is not accessible (HTTP Status: $HTTP_STATUS)"
    echo "Please check the bucket configuration and try again."
fi
