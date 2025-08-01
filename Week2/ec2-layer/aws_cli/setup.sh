#!/bin/bash

# Exit on error
set -e

echo "Creating infrastructure for Django web application..."

# Variables
AWS_REGION="us-east-1"
KEY_NAME="aws_keys"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0ff8a91507f77f867" # Amazon Linux 2 AMI (change according to your region)
ECR_REPO_NAME="django-web-app"
INSTANCE_NAME="django-web-server"

# Common tags
PROJECT_NAME="django-web-app"
ENVIRONMENT="development"
CREATED_BY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | cut -d'/' -f2 || echo "unknown")

# Load network configuration
echo "Loading network configuration..."
if [ -f "network-details.txt" ]; then
    source "network-details.txt"
    echo "Using existing network infrastructure..."
else
    echo "Network infrastructure not found. Creating network components..."
    ./network-setup.sh
    source "network-details.txt"
fi

# Validate network configuration
if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ] || [ -z "$SECURITY_GROUP_ID" ]; then
    echo "Error: Required network configuration variables are missing."
    echo "Please run network-setup.sh first to create the network infrastructure."
    exit 1
fi

echo "Network configuration loaded:"
echo "  VPC ID: $VPC_ID"
echo "  Subnet ID: $SUBNET_ID"
echo "  Security Group ID: $SECURITY_GROUP_ID"

# Create key pair if it doesn't exist
aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > ~/${KEY_NAME}.pem 2>/dev/null && \
  chmod 400 ~/${KEY_NAME}.pem || \
  echo "Key pair $KEY_NAME already exists"

# Check if instance already exists
EXISTING_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running,pending,stopped" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text 2>/dev/null)

if [ "$EXISTING_INSTANCE" != "None" ] && [ "$EXISTING_INSTANCE" != "" ]; then
  INSTANCE_ID=$EXISTING_INSTANCE
  echo "Using existing EC2 instance: $INSTANCE_ID"
else
  # Create EC2 instance
  echo "Creating EC2 instance..."
  INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}},{Key=Role,Value=web-server}]" \
  --count 1 \
  --output text \
  --query 'Instances[0].InstanceId')
  
  echo "Created EC2 instance: $INSTANCE_ID"
fi

# Wait for instance to be running
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "EC2 instance is running. Public IP: $PUBLIC_IP"

# Create ECR repository or use existing
echo "Creating ECR repository..."
aws ecr create-repository \
  --repository-name $ECR_REPO_NAME \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --tags Key=Name,Value=${PROJECT_NAME}-ecr Key=Project,Value=${PROJECT_NAME} Key=Environment,Value=${ENVIRONMENT} Key=CreatedBy,Value=${CREATED_BY} 2>/dev/null || \
  echo "ECR repository $ECR_REPO_NAME already exists"

# Get ECR repository URL
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME"

SSH_COMMAND="ssh -i ~/${KEY_NAME}.pem ec2-user@$PUBLIC_IP"

# Create output file with results
echo "Writing infrastructure details to output file..."
cat > infrastructure-details.txt << EOF
EC2_INSTANCE_ID=$INSTANCE_ID
EC2_PUBLIC_IP=$PUBLIC_IP
SECURITY_GROUP_ID=$SECURITY_GROUP_ID
ECR_REPOSITORY_URL=$ECR_URL
VPC_ID=$VPC_ID
SUBNET_ID=$SUBNET_ID
SSH_COMMAND="ssh -i ~/${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
EOF

echo "Infrastructure provisioning complete!"
echo "================================================"
echo "EC2 Instance ID: $INSTANCE_ID"
echo "EC2 Public IP: $PUBLIC_IP"
echo "ECR Repository URL: $ECR_URL"
echo "SSH Command: ssh -i ~/${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
echo "================================================"
echo "Details saved to infrastructure-details.txt"
