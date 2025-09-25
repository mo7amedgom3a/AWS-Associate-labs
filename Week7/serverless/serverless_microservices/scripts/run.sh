#!/bin/bash

# Script to run the database population scripts

# Get RDS endpoint from Terraform output
echo "Getting RDS endpoint from Terraform output..."
cd ../terraform
DB_HOST=$(terraform output -raw rds_endpoint 2>/dev/null)
DB_PORT=$(terraform output -raw rds_port 2>/dev/null || echo "3306")
DB_NAME=$(terraform output -raw rds_database_name 2>/dev/null || echo "products")
DB_USER=$(terraform output -raw rds_username 2>/dev/null || echo "admin")

# Get DynamoDB table name from Terraform output
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null || echo "serverless-ecommerce-dev-orders")

cd ../scripts

# Check if we got the RDS endpoint
if [ -z "$DB_HOST" ]; then
  echo "Warning: Could not get RDS endpoint from Terraform output."
  echo "Please enter RDS endpoint manually:"
  read -p "RDS Endpoint: " DB_HOST
fi

# Get password (don't store in script for security)
read -sp "RDS Password: " DB_PASSWORD
echo ""

# Export environment variables
export DB_HOST
export DB_PORT
export DB_NAME
export DB_USER
export DB_PASSWORD
export DYNAMODB_TABLE

echo "Installing dependencies..."
npm install

echo "Populating DynamoDB table: $DYNAMODB_TABLE"
node populate_dynamodb.js

echo "Populating RDS database at: $DB_HOST"
node populate_rds.js

echo "Done!"
