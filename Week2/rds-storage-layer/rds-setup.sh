#!/bin/bash

# Exit on error
set -e

# RDS Database Setup Script
# This script creates a private subnet and RDS MySQL instance for the Django web application

# Variables
AWS_REGION="us-east-1"
PROJECT_NAME="django-web-app"
ENVIRONMENT="development"
CREATED_BY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | cut -d'/' -f2 || echo "unknown")

# RDS Configuration
DB_INSTANCE_IDENTIFIER="django-db-instance"
DB_NAME="mydb"
DB_USERNAME="admin"
DB_PASSWORD="MySecurePassword123!"
DB_INSTANCE_CLASS="db.t3.micro"  # Free tier eligible
DB_ENGINE="mysql"
DB_ENGINE_VERSION="8.0.35"
DB_ALLOCATED_STORAGE="20"
DB_MAX_ALLOCATED_STORAGE="100"

# Network Configuration
PRIVATE_SUBNET_CIDR="10.0.2.0/24"
PRIVATE_SUBNET_AZ="${AWS_REGION}b"

# Output files
NETWORK_OUTPUT_FILE="../ec2-layer/aws_cli/network-details.txt"
RDS_OUTPUT_FILE="rds-details.txt"

# Clear the output file and start fresh
echo "# RDS Database Details - Generated on $(date)" > $RDS_OUTPUT_FILE
echo "# ================================================" >> $RDS_OUTPUT_FILE

echo "Setting up RDS MySQL database infrastructure..."

# Load existing network configuration
if [ -f "$NETWORK_OUTPUT_FILE" ]; then
    echo "Loading existing network configuration..."
    source "$NETWORK_OUTPUT_FILE"
    
    if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ]; then
        echo "Error: Required network configuration variables are missing."
        echo "Please run network-setup.sh first to create the network infrastructure."
        exit 1
    fi
    
    echo "Using existing VPC: $VPC_ID"
    echo "Using existing public subnet: $SUBNET_ID"
    echo "VPC_ID=$VPC_ID" >> $RDS_OUTPUT_FILE
    echo "PUBLIC_SUBNET_ID=$SUBNET_ID" >> $RDS_OUTPUT_FILE
else
    echo "Error: Network configuration file not found."
    echo "Please run network-setup.sh first to create the network infrastructure."
    exit 1
fi

# Create private subnet for RDS
echo "Creating private subnet for RDS..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_CIDR \
  --availability-zone $PRIVATE_SUBNET_AZ \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-subnet},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}},{Key=Type,Value=private}]" \
  --output text \
  --query 'Subnet.SubnetId' 2>/dev/null || \
  aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=cidr-block,Values=$PRIVATE_SUBNET_CIDR" \
  --query 'Subnets[0].SubnetId' \
  --output text)

echo "Using private subnet: $PRIVATE_SUBNET_ID"
echo "PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID" >> $RDS_OUTPUT_FILE

# Create route table for private subnet (no internet gateway route)
echo "Creating route table for private subnet..."
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-rt},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}},{Key=Type,Value=private}]" \
  --output text \
  --query 'RouteTable.RouteTableId' 2>/dev/null || \
  aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Type,Values=private" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

# Associate route table with private subnet (ignore if already associated)
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_ROUTE_TABLE_ID \
  --subnet-id $PRIVATE_SUBNET_ID 2>/dev/null || true

echo "Using private route table: $PRIVATE_ROUTE_TABLE_ID"
echo "PRIVATE_ROUTE_TABLE_ID=$PRIVATE_ROUTE_TABLE_ID" >> $RDS_OUTPUT_FILE

# Create security group for RDS
echo "Creating security group for RDS..."
RDS_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name django-rds-sg \
  --description "Security group for RDS MySQL database" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_NAME}-rds-sg},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=CreatedBy,Value=${CREATED_BY}}]" \
  --output text \
  --query 'GroupId' 2>/dev/null || \
  aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=django-rds-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "Using RDS security group: $RDS_SECURITY_GROUP_ID"
echo "RDS_SECURITY_GROUP_ID=$RDS_SECURITY_GROUP_ID" >> $RDS_OUTPUT_FILE

# Add inbound rule to allow MySQL access from the public subnet (EC2 instance)
echo "Configuring RDS security group rules..."
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SECURITY_GROUP_ID \
  --protocol tcp \
  --port 3306 \
  --source-group $SECURITY_GROUP_ID 2>/dev/null || true

# Create subnet group for RDS
echo "Creating DB subnet group..."
DB_SUBNET_GROUP_NAME="${PROJECT_NAME}-db-subnet-group"

aws rds create-db-subnet-group \
  --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
  --db-subnet-group-description "Subnet group for Django RDS instance" \
  --subnet-ids $SUBNET_ID $PRIVATE_SUBNET_ID \
  --tags Key=Name,Value=${PROJECT_NAME}-db-subnet-group Key=Project,Value=${PROJECT_NAME} Key=Environment,Value=${ENVIRONMENT} Key=CreatedBy,Value=${CREATED_BY} 2>/dev/null || \
  echo "DB subnet group $DB_SUBNET_GROUP_NAME already exists"

echo "DB_SUBNET_GROUP_NAME=$DB_SUBNET_GROUP_NAME" >> $RDS_OUTPUT_FILE

# Check if RDS instance already exists
echo "Checking for existing RDS instance..."
EXISTING_DB=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
  --query 'DBInstances[0].DBInstanceIdentifier' \
  --output text 2>/dev/null || echo "")

if [ "$EXISTING_DB" != "None" ] && [ "$EXISTING_DB" != "" ] && [ "$EXISTING_DB" != "null" ]; then
    echo "RDS instance $DB_INSTANCE_IDENTIFIER already exists"
    echo "DB_INSTANCE_IDENTIFIER=$DB_INSTANCE_IDENTIFIER" >> $RDS_OUTPUT_FILE
    
    # Get existing instance details
    DB_ENDPOINT=$(aws rds describe-db-instances \
      --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
      --query 'DBInstances[0].Endpoint.Address' \
      --output text)
    DB_PORT=$(aws rds describe-db-instances \
      --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
      --query 'DBInstances[0].Endpoint.Port' \
      --output text)
    
    echo "DB_ENDPOINT=$DB_ENDPOINT" >> $RDS_OUTPUT_FILE
    echo "DB_PORT=$DB_PORT" >> $RDS_OUTPUT_FILE
    echo "DB_NAME=$DB_NAME" >> $RDS_OUTPUT_FILE
    echo "DB_USERNAME=$DB_USERNAME" >> $RDS_OUTPUT_FILE
    echo "DB_PASSWORD=$DB_PASSWORD" >> $RDS_OUTPUT_FILE
    echo "DB_ENGINE=$DB_ENGINE" >> $RDS_OUTPUT_FILE
    echo "DB_ENGINE_VERSION=$DB_ENGINE_VERSION" >> $RDS_OUTPUT_FILE
    echo "DB_INSTANCE_CLASS=$DB_INSTANCE_CLASS" >> $RDS_OUTPUT_FILE
    
    echo "Using existing RDS instance with endpoint: $DB_ENDPOINT"
else
    # Create RDS instance
    echo "DB_INSTANCE_IDENTIFIER=$DB_INSTANCE_IDENTIFIER" >> $RDS_OUTPUT_FILE
    echo "DB_NAME=$DB_NAME" >> $RDS_OUTPUT_FILE
    echo "DB_USERNAME=$DB_USERNAME" >> $RDS_OUTPUT_FILE
    echo "DB_PASSWORD=$DB_PASSWORD" >> $RDS_OUTPUT_FILE
    echo "DB_ENGINE=$DB_ENGINE" >> $RDS_OUTPUT_FILE
    echo "DB_ENGINE_VERSION=$DB_ENGINE_VERSION" >> $RDS_OUTPUT_FILE
    echo "DB_INSTANCE_CLASS=$DB_INSTANCE_CLASS" >> $RDS_OUTPUT_FILE
    
    aws rds create-db-instance \
      --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
      --db-instance-class $DB_INSTANCE_CLASS \
      --engine $DB_ENGINE \
      --engine-version $DB_ENGINE_VERSION \
      --master-username $DB_USERNAME \
      --master-user-password $DB_PASSWORD \
      --allocated-storage $DB_ALLOCATED_STORAGE \
      --max-allocated-storage $DB_MAX_ALLOCATED_STORAGE \
      --storage-type gp2 \
      --db-name $DB_NAME \
      --vpc-security-group-ids $RDS_SECURITY_GROUP_ID \
      --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
      --backup-retention-period 7 \
      --preferred-backup-window "03:00-04:00" \
      --preferred-maintenance-window "sun:04:00-sun:05:00" \
      --deletion-protection \
      --storage-encrypted \
      --tags Key=Name,Value=${PROJECT_NAME}-rds Key=Project,Value=${PROJECT_NAME} Key=Environment,Value=${ENVIRONMENT} Key=CreatedBy,Value=${CREATED_BY}

    echo "RDS instance creation initiated. Waiting for instance to be available..."
    
    # Wait for RDS instance to be available
    aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER
    
    # Get endpoint and port
    DB_ENDPOINT=$(aws rds describe-db-instances \
      --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
      --query 'DBInstances[0].Endpoint.Address' \
      --output text)
    DB_PORT=$(aws rds describe-db-instances \
      --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
      --query 'DBInstances[0].Endpoint.Port' \
      --output text)
    
    echo "DB_ENDPOINT=$DB_ENDPOINT" >> $RDS_OUTPUT_FILE
    echo "DB_PORT=$DB_PORT" >> $RDS_OUTPUT_FILE
    
    echo "RDS instance created successfully!"
fi

# Set file permissions
chmod 600 $RDS_OUTPUT_FILE

echo "RDS infrastructure setup complete!"
echo "================================================"
echo "DB Instance Identifier: $DB_INSTANCE_IDENTIFIER"
echo "DB Endpoint: $DB_ENDPOINT"
echo "DB Port: $DB_PORT"
echo "DB Name: $DB_NAME"
echo "DB Username: $DB_USERNAME"
echo "Private Subnet ID: $PRIVATE_SUBNET_ID"
echo "RDS Security Group ID: $RDS_SECURITY_GROUP_ID"
echo "================================================"
echo "RDS details saved to $RDS_OUTPUT_FILE"

# Export variables for use in other scripts
export DB_INSTANCE_IDENTIFIER
export DB_ENDPOINT
export DB_PORT
export DB_NAME
export DB_USERNAME
export DB_PASSWORD
export PRIVATE_SUBNET_ID
export RDS_SECURITY_GROUP_ID 