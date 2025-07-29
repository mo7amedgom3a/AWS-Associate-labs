#!/bin/bash

# Exit on error
set -e

echo "Creating infrastructure for Django web application..."

# Variables
AWS_REGION="us-east-1"
KEY_NAME="aws_keys"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0ff8a91507f77f867" # Amazon Linux 2 AMI (change according to your region)
VPC_ID=""
SUBNET_ID=""
SECURITY_GROUP_ID=""
ECR_REPO_NAME="django-web-app"
INSTANCE_NAME="django-web-server"

# Common tags
PROJECT_NAME="django-web-app"
ENVIRONMENT="development"
CREATED_BY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | cut -d'/' -f2 || echo "unknown")

# Create VPC or use existing
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_NAME}-vpc},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}}]" \
  --output text \
  --query 'Vpc.VpcId' 2>/dev/null || \
  aws ec2 describe-vpcs \
  --filters "Name=cidr-block,Values=10.0.0.0/16" \
  --query 'Vpcs[0].VpcId' \
  --output text)

# Enable DNS hostnames for the VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames 2>/dev/null || true

echo "Using VPC: $VPC_ID"

# Create Internet Gateway or use existing
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-igw},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}}]" \
  --output text \
  --query 'InternetGateway.InternetGatewayId' 2>/dev/null || \
  aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text)

# Attach Internet Gateway to VPC (ignore if already attached)
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID 2>/dev/null || true

echo "Using Internet Gateway: $IGW_ID"

# Create public subnet or use existing
echo "Creating public subnet..."
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${AWS_REGION}a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-subnet},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}},{Key=Type,Value=public}]" \
  --output text \
  --query 'Subnet.SubnetId' 2>/dev/null || \
  aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=cidr-block,Values=10.0.1.0/24" \
  --query 'Subnets[0].SubnetId' \
  --output text)

# Enable auto-assign public IP for the subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_ID \
  --map-public-ip-on-launch 2>/dev/null || true

echo "Using public subnet: $SUBNET_ID"

# Create route table for public subnet or use existing
echo "Creating route table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-rt},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}},{Key=Type,Value=public}]" \
  --output text \
  --query 'RouteTable.RouteTableId' 2>/dev/null || \
  aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.subnet-id,Values=$SUBNET_ID" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

# Add route to Internet Gateway (ignore if route exists)
aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID 2>/dev/null || true

# Associate route table with public subnet (ignore if already associated)
aws ec2 associate-route-table \
  --route-table-id $ROUTE_TABLE_ID \
  --subnet-id $SUBNET_ID 2>/dev/null || true

echo "Using route table: $ROUTE_TABLE_ID"

# Create security group or use existing
echo "Creating security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name django-web-sg \
  --description "Security group for Django web server" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_NAME}-sg},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}}]" \
  --output text \
  --query 'GroupId' 2>/dev/null || \
  aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=django-web-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "Using security group: $SECURITY_GROUP_ID"

# Add inbound rules to security group (ignore if rules exist)
echo "Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 2>/dev/null || true

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 2>/dev/null || true

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 8000 \
  --cidr 0.0.0.0/0 2>/dev/null || true

# Get current IP address for SSH access
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Allowing SSH access from $MY_IP"

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 22 \
  --cidr $MY_IP/32 2>/dev/null || true

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
echo "SSH Command: ssh -i ~/${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
SSH_COMMAND="ssh -i ~/${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
EOF

echo "Infrastructure provisioning complete!"
echo "================================================"
echo "EC2 Instance ID: $INSTANCE_ID"
echo "EC2 Public IP: $PUBLIC_IP"
echo "ECR Repository URL: $ECR_URL"
echo "SSH Command: ssh -i ~/${KEY_NAME}.pem ec2-user@$PUBLIC_IP.compute-1.amazonaws.com"
echo "================================================"
echo "Details saved to infrastructure-details.txt"
