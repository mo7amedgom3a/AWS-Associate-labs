#!/bin/bash

# Cleanup script for IAM Users, Groups, and Policies
# This script removes all resources created by setup.sh

set -e  # Exit on error

echo "Starting IAM cleanup with AWS CLI..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Run 'aws configure' first."
    exit 1
fi

# Function to safely execute AWS commands and continue on "not found" errors
safe_aws_command() {
    local command="$1"
    local description="$2"
    
    echo "Attempting: $description"
    if eval "$command" 2>/dev/null; then
        echo "✓ Success: $description"
    else
        local exit_code=$? # get the exit code of the last command
        # Check if the exit code is 254 (resource not found) or if the command contains "not found" type messages
        # This is a common exit code for AWS CLI commands
        # indicating that the resource does not exist.
        if [[ $exit_code -eq 254 ]] || aws_error_contains_not_found "$command"; then
            echo "⚠ Skipped: $description (resource not found)"
        else
            echo "✗ Failed: $description"
            return $exit_code
        fi
    fi
}

# Function to check if AWS error contains "not found" type messages
aws_error_contains_not_found() {
    local command="$1"
    local error_output
    error_output=$(eval "$command" 2>&1 || true)
    # Check if the error output contains common "not found" messages
    # This is useful for commands that might fail due to resources not existing.
    # For example, "NoSuchEntity", "NotFound", or "does not exist".
    if echo "$error_output" | grep -q -E "(NoSuchEntity|NotFound|does not exist)"; then
        return 0
    else
        return 1
    fi
}

echo "Removing users from groups..."
# Remove users from groups
safe_aws_command "aws iam remove-user-from-group --group-name EC2-Admin --user-name user-1" "Remove user-1 from EC2-Admin group"
safe_aws_command "aws iam remove-user-from-group --group-name EC2-Support --user-name user-2" "Remove user-2 from EC2-Support group"
safe_aws_command "aws iam remove-user-from-group --group-name S3-Support --user-name user-3" "Remove user-3 from S3-Support group"

echo "Removing policies from groups..."
# Remove inline policy from EC2-Admin group
safe_aws_command "aws iam delete-group-policy --group-name EC2-Admin --policy-name EC2AdminInlinePolicy" "Delete EC2AdminInlinePolicy from EC2-Admin group"

# Detach managed policies from groups
safe_aws_command "aws iam detach-group-policy --group-name EC2-Support --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess" "Detach AmazonEC2ReadOnlyAccess from EC2-Support group"
safe_aws_command "aws iam detach-group-policy --group-name S3-Support --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" "Detach AmazonS3ReadOnlyAccess from S3-Support group"

echo "Deleting IAM groups..."
# Delete IAM groups
safe_aws_command "aws iam delete-group --group-name EC2-Admin" "Delete EC2-Admin group"
safe_aws_command "aws iam delete-group --group-name EC2-Support" "Delete EC2-Support group"
safe_aws_command "aws iam delete-group --group-name S3-Support" "Delete S3-Support group"

echo "Deleting IAM users..."
# Delete IAM users
safe_aws_command "aws iam delete-user --user-name user-1" "Delete user-1"
safe_aws_command "aws iam delete-user --user-name user-2" "Delete user-2"
safe_aws_command "aws iam delete-user --user-name user-3" "Delete user-3"

echo "IAM cleanup completed successfully!"
