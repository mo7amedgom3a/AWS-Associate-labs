#!/bin/bash

# Exit on error
set -e

# Network Infrastructure Setup Script
# This script creates and configures all network components for the Django web application

# Variables
AWS_REGION="us-east-1"
PROJECT_NAME="django-web-app"
ENVIRONMENT="development"
CREATED_BY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | cut -d'/' -f2 || echo "unknown")

# Output file for network details
NETWORK_OUTPUT_FILE="network-details.txt"

echo "Setting up network infrastructure..."

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

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 2>/dev/null || true # Allow SSH access from anywhere

# Create output file with network details
echo "Writing network details to output file..."
cat > $NETWORK_OUTPUT_FILE << EOF
# Network Infrastructure Details
VPC_ID=$VPC_ID
SUBNET_ID=$SUBNET_ID
SECURITY_GROUP_ID=$SECURITY_GROUP_ID
ROUTE_TABLE_ID=$ROUTE_TABLE_ID
IGW_ID=$IGW_ID
AWS_REGION=$AWS_REGION
PROJECT_NAME=$PROJECT_NAME
ENVIRONMENT=$ENVIRONMENT
EOF
chmod 600 $NETWORK_OUTPUT_FILE

echo "Network infrastructure setup complete!"
echo "================================================"
echo "VPC ID: $VPC_ID"
echo "Subnet ID: $SUBNET_ID"
echo "Security Group ID: $SECURITY_GROUP_ID"
echo "Route Table ID: $ROUTE_TABLE_ID"
echo "Internet Gateway ID: $IGW_ID"
echo "================================================"
echo "Network details saved to $NETWORK_OUTPUT_FILE"

# Export variables for use in other scripts
export VPC_ID
export SUBNET_ID
export SECURITY_GROUP_ID
export ROUTE_TABLE_ID
export IGW_ID 