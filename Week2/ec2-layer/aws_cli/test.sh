#!/bin/bash

# Exit on error
set -e

# Check if infrastructure-details.txt exists
if [ ! -f infrastructure-details.txt ]; then
  echo "Error: infrastructure-details.txt not found. Run setup.sh first."
  exit 1
fi

# Load resource IDs from the output file
source infrastructure-details.txt

# Test SSH connection
echo "Testing SSH connection to $EC2_PUBLIC_IP..."
if [ -f "$KEY_PATH" ]; then
  echo "Using key file: $KEY_PATH"
  ssh -i $KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@$EC2_PUBLIC_IP exit 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "✅ SSH connection successful!"
  else
    echo "❌ SSH connection failed. Check your key pair and security group settings."
  fi
else
  echo "❌ Key file not found at $KEY_PATH. Cannot test SSH connection."
fi

# Test ECR access
echo "Testing ECR repository access..."
aws ecr describe-repositories --repository-names $(echo $ECR_REPOSITORY_URL | cut -d '/' -f 2) > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ ECR repository access successful!"
else
  echo "❌ ECR repository access failed. Check your AWS credentials."
fi

# Get instance status
echo "Checking EC2 instance status..."
STATUS=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text)
echo "EC2 instance status: $STATUS"

echo "Testing complete!"
