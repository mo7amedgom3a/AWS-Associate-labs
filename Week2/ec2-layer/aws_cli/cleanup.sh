#!/bin/bash

# Exit on error but continue if resources don't exist
set -e

echo "Cleaning up infrastructure..."

# Check if infrastructure-details.txt exists
if [ ! -f infrastructure-details.txt ]; then
  echo "Error: infrastructure-details.txt not found. Cannot clean up resources."
  exit 1
fi

# Load resource IDs from the output file
source infrastructure-details.txt

echo "Terminating EC2 instance: $EC2_INSTANCE_ID"
aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_ID 2>/dev/null || {
  echo "Warning: Failed to terminate instance $EC2_INSTANCE_ID (may not exist)"
}

echo "Waiting for instance to terminate..."
aws ec2 wait instance-terminated --instance-ids $EC2_INSTANCE_ID 2>/dev/null || {
  echo "Warning: Instance $EC2_INSTANCE_ID may already be terminated"
}

echo "Deleting security group: $SECURITY_GROUP_ID"
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID 2>/dev/null || {
  echo "Warning: Failed to delete security group $SECURITY_GROUP_ID (may not exist)"
}

echo "Deleting ECR repository..."
aws ecr delete-repository --repository-name $(echo $ECR_REPOSITORY_URL | cut -d '/' -f 2) --force 2>/dev/null || {
  echo "Warning: Failed to delete ECR repository (may not exist)"
}

echo "Deleting VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null || {
  echo "Warning: Failed to delete VPC $VPC_ID (may not exist or have dependencies)"
}

echo "Removing infrastructure-details.txt file..."
rm -f infrastructure-details.txt

echo "Cleanup complete!"
