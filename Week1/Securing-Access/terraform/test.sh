#!/bin/bash

# IAM User Access Testing Script for Terraform deployment
# This script tests the access permissions of each IAM user created by Terraform

set -e  # Exit on error

# Text formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo "=== IAM User Access Testing Script for Terraform Deployment ==="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not configured. Run 'aws configure' first.${RESET}"
    exit 1
fi

# Check if the terraform has been applied
if [[ ! -f terraform.tfstate ]]; then
    echo -e "${RED}Error: terraform.tfstate not found. Please run 'terraform apply' first.${RESET}"
    exit 1
fi

# Function to create temporary AWS CLI profile
create_temp_profile() {
    local user=$1
    local access_key=$2
    local secret_key=$3
    
    aws configure set profile.${user} aws_access_key_id ${access_key}
    aws configure set profile.${user} aws_secret_access_key ${secret_key}
    aws configure set profile.${user} region $(aws configure get region)
}

# Function to remove temporary AWS CLI profile
remove_temp_profile() {
    local user=$1
    aws configure --profile ${user} --no-verify-ssl
}

# Function to test EC2 permissions
test_ec2_permissions() {
    local user=$1
    local profile=$1
    
    echo -e "\n${YELLOW}Testing EC2 permissions for ${user}...${RESET}"
    
    # Test EC2 describe instances (all users in EC2-Admin and EC2-Support should have access)
    echo "Testing EC2 describe instances..."
    if aws ec2 describe-instances --profile ${profile} --query 'Reservations[*].Instances[*].[InstanceId]' --output text &> /dev/null; then
        echo -e "${GREEN}✓ Success: ${user} can describe EC2 instances${RESET}"
    else
        echo -e "${RED}✗ Failed: ${user} cannot describe EC2 instances${RESET}"
    fi
    
    # Test EC2 start/stop instances (only users in EC2-Admin should have access)
    echo "Testing EC2 start/stop instances..."
    # We'll use a dry run to test permissions without actually starting instances
    if aws ec2 start-instances --instance-ids i-12345678 --dry-run --profile ${profile} &> /dev/null; then
        echo -e "${GREEN}✓ Success: ${user} can start/stop EC2 instances${RESET}"
    else
        if [[ ${user} == "user-1" ]]; then
            echo -e "${RED}✗ Failed: ${user} should be able to start/stop EC2 instances but cannot${RESET}"
        else
            echo -e "${GREEN}✓ Success: ${user} correctly cannot start/stop EC2 instances${RESET}"
        fi
    fi
}

# Function to test S3 permissions
test_s3_permissions() {
    local user=$1
    local profile=$1
    
    echo -e "\n${YELLOW}Testing S3 permissions for ${user}...${RESET}"
    
    # Test S3 list buckets (users in S3-Support should have access)
    echo "Testing S3 list buckets..."
    if aws s3 ls --profile ${profile} &> /dev/null; then
        echo -e "${GREEN}✓ Success: ${user} can list S3 buckets${RESET}"
    else
        if [[ ${user} == "user-3" ]]; then
            echo -e "${RED}✗ Failed: ${user} should be able to list S3 buckets but cannot${RESET}"
        else
            echo -e "${GREEN}✓ Success: ${user} correctly cannot list S3 buckets${RESET}"
        fi
    fi
    
    # Test S3 create bucket (no users should have this permission)
    echo "Testing S3 create bucket (should fail for all users)..."
    local bucket_name="test-bucket-$(date +%s)"
    if ! aws s3 mb s3://${bucket_name} --profile ${profile} &> /dev/null; then
        echo -e "${GREEN}✓ Success: ${user} correctly cannot create S3 buckets${RESET}"
    else
        echo -e "${RED}✗ Failed: ${user} should not be able to create S3 buckets but can${RESET}"
        # Clean up the created bucket
        aws s3 rb s3://${bucket_name} --profile ${profile} &> /dev/null
    fi
}

# Main testing function
test_user_access() {
    local user=$1
    
    echo -e "\n${YELLOW}=== Testing access for ${user} ===${RESET}"
    
    # Create access keys for testing
    echo "Creating temporary access key for ${user}..."
    local key_output=$(aws iam create-access-key --user-name ${user})
    local access_key=$(echo ${key_output} | jq -r '.AccessKey.AccessKeyId')
    local secret_key=$(echo ${key_output} | jq -r '.AccessKey.SecretAccessKey')
    
    # Create a temporary profile
    create_temp_profile ${user} ${access_key} ${secret_key}
    
    # Run tests based on user group
    if [[ ${user} == "user-1" ]]; then
        test_ec2_permissions ${user}
    elif [[ ${user} == "user-2" ]]; then
        test_ec2_permissions ${user}
    elif [[ ${user} == "user-3" ]]; then
        test_s3_permissions ${user}
    fi
    
    # Clean up
    echo -e "\nCleaning up test resources for ${user}..."
    aws iam delete-access-key --user-name ${user} --access-key-id ${access_key}
    remove_temp_profile ${user}
}

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed. Please install it with 'sudo apt-get install jq' or equivalent.${RESET}"
    exit 1
fi

# Run tests for each user
echo "Starting permission tests..."
test_user_access "user-1"
test_user_access "user-2"
test_user_access "user-3"

echo -e "\n${GREEN}All tests completed!${RESET}"
echo "Note: This script tests permissions but does not test actual resource access."
echo "For a complete test, you would need to have actual EC2 instances and S3 buckets."
