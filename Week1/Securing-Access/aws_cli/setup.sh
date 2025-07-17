#!/bin/bash

# IAM Users, Groups, and Policies Management using AWS CLI
# This script creates the IAM structure as described in the lab requirements

set -e  # Exit on error

echo "Starting IAM setup with AWS CLI..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Run 'aws configure' first."
    exit 1
fi

echo "Creating IAM users..."
# Create IAM users
aws iam create-user --user-name user-1
aws iam create-user --user-name user-2
aws iam create-user --user-name user-3

echo "Creating IAM groups..."
# Create IAM groups
aws iam create-group --group-name EC2-Admin
aws iam create-group --group-name EC2-Support
aws iam create-group --group-name S3-Support

echo "Creating and attaching policies..."
# Create inline policy for EC2-Admin group
EC2_ADMIN_POLICY=$(cat << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# Apply inline policy to EC2-Admin group
aws iam put-group-policy \
    --group-name EC2-Admin \
    --policy-name EC2AdminInlinePolicy \
    --policy-document "$EC2_ADMIN_POLICY"

# Attach managed policies to groups
aws iam attach-group-policy \
    --group-name EC2-Support \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess

aws iam attach-group-policy \
    --group-name S3-Support \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

echo "Adding users to groups..."
# Add users to groups
aws iam add-user-to-group --group-name EC2-Admin --user-name user-1
aws iam add-user-to-group --group-name EC2-Support --user-name user-2
aws iam add-user-to-group --group-name S3-Support --user-name user-3

echo "IAM setup completed successfully!"
echo "Summary:"
echo "- Created users: user-1, user-2, user-3"
echo "- Created groups: EC2-Admin, EC2-Support, S3-Support"
echo "- Assigned inline policy for EC2 full access to EC2-Admin"
echo "- Assigned managed policy for EC2 read-only to EC2-Support"
echo "- Assigned managed policy for S3 read-only to S3-Support"
echo "- Added user-1 to EC2-Admin"
echo "- Added user-2 to EC2-Support"
echo "- Added user-3 to S3-Support"
