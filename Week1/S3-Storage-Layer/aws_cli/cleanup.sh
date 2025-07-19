#!/bin/bash

# Script to clean up S3 static website resources
# Author: mo7amedgom3a
# Date: July 19, 2025

set -e  # Exit on error

echo "=== S3 Static Website Cleanup Script ==="

# Get bucket name from saved file or user input
if [ -f .bucket_name ] && [ -f .bucket_region ]; then
    BUCKET_NAME=$(cat .bucket_name)
    REGION=$(cat .bucket_region)
    echo "Found saved deployment: Bucket=$BUCKET_NAME, Region=$REGION"
else
    echo "No saved deployment found."
    read -p "Enter bucket name to delete: " BUCKET_NAME
    read -p "Enter region: " REGION
fi

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: No bucket name provided."
    exit 1
fi

echo "This script will delete all contents of bucket '$BUCKET_NAME' and remove the bucket itself."
read -p "Are you sure you want to proceed? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Step 1: Delete all objects in the bucket
echo "Step 1: Deleting all objects from bucket $BUCKET_NAME"
aws s3 rm "s3://$BUCKET_NAME" --recursive

echo "All objects deleted successfully!"

# Step 2: Delete the bucket
echo "Step 2: Deleting the bucket"
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"

echo "Bucket deleted successfully!"

# Clean up local tracking files
if [ -f .bucket_name ]; then rm .bucket_name; fi
if [ -f .bucket_region ]; then rm .bucket_region; fi

echo "=== Cleanup Complete! ==="
echo "All resources associated with your static website have been removed."
