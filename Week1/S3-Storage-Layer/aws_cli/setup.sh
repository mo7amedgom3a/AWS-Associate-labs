#!/bin/bash

# Script to deploy static website to Amazon S3 using AWS CLI
# Author: mo7amedgom3a
# Date: July 19, 2025

set -e  # Exit on error
# colors variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BUCKET_NAME="mycafe-website-$(date +%s)"  # Appending timestamp for uniqueness
REGION="us-east-1"
WEBSITE_DIR="../static-website"  # Path to the static website files

echo "=== S3 Static Website Deployment Script ==="
echo "This script will deploy a static website to Amazon S3."

# Step 1: Create an S3 bucket
echo "Step 1: Creating S3 bucket: $BUCKET_NAME"
if aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" 2>/dev/null; then
    echo -e "${GREEN}Bucket created successfully!${NC}"
else
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo -e "${YELLOW}Bucket already exists, continuing with deployment...${NC}"
    else
        echo -e "${RED}Error: Failed to create or access bucket $BUCKET_NAME${NC}"
        exit 1
    fi
fi

# Step 2: Enable public access to the bucket
echo "Step 2: Configuring bucket to allow public access"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo -e "${GREEN}Public access configured!${NC}"

# Step 3: Upload website files
echo "Step 3: Uploading website files from $WEBSITE_DIR"
if [ -d "$WEBSITE_DIR" ]; then
    aws s3 sync "$WEBSITE_DIR" "s3://$BUCKET_NAME"
    echo -e "${GREEN}Website files uploaded successfully!${NC}"
else
    echo -e "${RED}Error: Website directory not found at $WEBSITE_DIR${NC}"
    exit 1
fi

# Step 4: Enable static website hosting
echo "Step 4: Enabling static website hosting"
aws s3 website "s3://$BUCKET_NAME" --index-document index.html --error-document error.html

echo -e "${GREEN}Static website hosting enabled!${NC}"

# Step 5: Set bucket policy for public read access
echo "Step 5: Setting bucket policy for public read access"
POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::'$BUCKET_NAME'/*"
    }
  ]
}'

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "$POLICY"

echo -e "${GREEN}Bucket policy set successfully!${NC}"

# Print website URL
WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "=== Deployment Complete! ==="
echo "Your website is now available at: $WEBSITE_URL"
echo "Bucket name: $BUCKET_NAME (save this for future reference or cleanup)"
echo "Region: $REGION"

# Save deployment info for later reference
echo "$BUCKET_NAME" > .bucket_name
echo "$REGION" > .bucket_region
