#!/bin/bash

# Exit on error
set -e

echo "Testing Terraform infrastructure..."

# Check if infrastructure-details.txt exists
if [ ! -f infrastructure-details.txt ]; then
  echo "Error: infrastructure-details.txt not found. Run 'terraform apply' first."
  exit 1
fi

# Load resource IDs from the output file
source infrastructure-details.txt

# Test EC2 instance
echo "Testing EC2 instance status..."
INSTANCE_STATUS=$(aws ec2 describe-instances \
  --instance-ids $EC2_INSTANCE_ID \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text)

if [ "$INSTANCE_STATUS" = "running" ]; then
  echo "✅ EC2 instance is running!"
else
  echo "❌ EC2 instance is not running (status: $INSTANCE_STATUS)"
fi

# Test ECR access
echo "Testing ECR repository access..."
REPO_NAME=$(echo $ECR_REPOSITORY_URL | cut -d '/' -f 2)
aws ecr describe-repositories --repository-names $REPO_NAME > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ ECR repository access successful!"
else
  echo "❌ ECR repository access failed. Check your AWS credentials."
fi

# Check if key file exists
KEY_PATH=$(echo $SSH_COMMAND | grep -o '\-i [^ ]*' | cut -d ' ' -f 2)
echo "Checking key file..."
if [ -f "$KEY_PATH" ]; then
  echo "✅ Key file exists at $KEY_PATH"
  if [ $(stat -c %a "$KEY_PATH") = "400" ]; then
    echo "✅ Key file has correct permissions (400)"
  else
    echo "❌ Key file has incorrect permissions. Run: chmod 400 $KEY_PATH"
  fi
else
  echo "❌ Key file not found at $KEY_PATH"
fi

# Test SSH connection (without actually connecting)
echo "Testing SSH connection to $EC2_PUBLIC_IP (ping only)..."
ping -c 1 $EC2_PUBLIC_IP > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ Host is reachable via ping"
else
  echo "❌ Host is not responding to ping (may be normal due to firewall settings)"
fi

echo "To connect via SSH, use:"
echo "$SSH_COMMAND"

echo "Testing complete!"
