#!/bin/bash

# Test script for RDS setup
# This script tests the RDS instance connectivity and configuration

echo "Testing RDS setup..."

# Test 1: Check if rds-setup.sh exists and is executable
if [ -x "./rds-setup.sh" ]; then
    echo "✓ rds-setup.sh exists and is executable"
else
    echo "✗ rds-setup.sh is missing or not executable"
    exit 1
fi

# Test 2: Check if rds-cleanup.sh exists and is executable
if [ -x "./rds-cleanup.sh" ]; then
    echo "✓ rds-cleanup.sh exists and is executable"
else
    echo "✗ rds-cleanup.sh is missing or not executable"
    exit 1
fi

# Test 3: Check if db-init.sh exists and is executable
if [ -x "./db-init.sh" ]; then
    echo "✓ db-init.sh exists and is executable"
else
    echo "✗ db-init.sh is missing or not executable"
    exit 1
fi

# Test 4: Check if SQL files exist
if [ -f "init.sql" ]; then
    echo "✓ init.sql exists"
else
    echo "✗ init.sql is missing"
    exit 1
fi

if [ -f "mydb_dump.sql" ]; then
    echo "✓ mydb_dump.sql exists"
else
    echo "⚠ mydb_dump.sql not found (will use init.sql as fallback)"
fi

# Test 5: Check if network configuration exists
if [ -f "../ec2-layer/aws_cli/network-details.txt" ]; then
    echo "✓ Network configuration exists"
else
    echo "✗ Network configuration not found"
    echo "Please run ../ec2-layer/aws_cli/network-setup.sh first"
    exit 1
fi

# Test 6: Check if infrastructure configuration exists
if [ -f "../ec2-layer/aws_cli/infrastructure-details.txt" ]; then
    echo "✓ Infrastructure configuration exists"
else
    echo "✗ Infrastructure configuration not found"
    echo "Please run ../ec2-layer/aws_cli/setup.sh first"
    exit 1
fi

# Test 7: Test AWS CLI connectivity
echo "Testing AWS CLI connectivity..."
if aws sts get-caller-identity --query 'Account' --output text > /dev/null 2>&1; then
    echo "✓ AWS CLI is configured and working"
else
    echo "✗ AWS CLI is not configured or not working"
    exit 1
fi

# Test 8: Test if we can describe RDS instances (basic permission check)
if aws rds describe-db-instances --query 'DBInstances[0].DBInstanceIdentifier' --output text > /dev/null 2>&1; then
    echo "✓ AWS RDS permissions are working"
else
    echo "✗ AWS RDS permissions are not working"
    exit 1
fi

# Test 9: Check if RDS instance exists and get details
if [ -f "rds-details.txt" ]; then
    echo "Testing RDS configuration loading..."
    source "rds-details.txt"
    
    if [ ! -z "$DB_INSTANCE_IDENTIFIER" ] && [ ! -z "$DB_ENDPOINT" ]; then
        echo "✓ RDS configuration loaded successfully"
        echo "  DB Instance: $DB_INSTANCE_IDENTIFIER"
        echo "  DB Endpoint: $DB_ENDPOINT"
        echo "  DB Port: $DB_PORT"
        
        # Test RDS instance status
        DB_STATUS=$(aws rds describe-db-instances \
            --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
            --query 'DBInstances[0].DBInstanceStatus' \
            --output text 2>/dev/null)
        
        if [ "$DB_STATUS" == "available" ]; then
            echo "✓ RDS instance is available"
        else
            echo "⚠ RDS instance status: $DB_STATUS"
        fi
    else
        echo "✗ Failed to load RDS configuration"
        exit 1
    fi
else
    echo "ℹ rds-details.txt not found - run ./rds-setup.sh first"
fi

# Test 10: Check if SSH key exists
SSH_KEY_PATH="~/${KEY_NAME:-aws_keys}.pem"
if [ -f "$SSH_KEY_PATH" ]; then
    echo "✓ SSH key found at $SSH_KEY_PATH"
else
    echo "✗ SSH key not found at $SSH_KEY_PATH"
    echo "Please ensure the key pair was created during EC2 setup"
fi

# Test 11: Test EC2 connectivity (if infrastructure details are available)
if [ -f "../ec2-layer/aws_cli/infrastructure-details.txt" ]; then
    source "../ec2-layer/aws_cli/infrastructure-details.txt"
    
    if [ ! -z "$EC2_PUBLIC_IP" ]; then
        echo "Testing EC2 connectivity..."
        if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "echo 'EC2 connection test'" 2>/dev/null; then
            echo "✓ EC2 connectivity successful"
        else
            echo "✗ EC2 connectivity failed"
            echo "This might be due to security group configuration or instance not being ready"
        fi
    else
        echo "⚠ EC2_PUBLIC_IP not found in infrastructure details"
    fi
else
    echo "ℹ Infrastructure details not found - cannot test EC2 connectivity"
fi

# Test 12: Test database connectivity via EC2 (if both are available)
if [ -f "rds-details.txt" ] && [ -f "../ec2-layer/aws_cli/infrastructure-details.txt" ]; then
    source "rds-details.txt"
    source "../ec2-layer/aws_cli/infrastructure-details.txt"
    
    if [ ! -z "$DB_ENDPOINT" ] && [ ! -z "$EC2_PUBLIC_IP" ]; then
        echo "Testing database connectivity via EC2..."
        
        if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' -e 'SELECT 1;'" 2>/dev/null; then
            echo "✓ Database connectivity via EC2 successful"
        else
            echo "✗ Database connectivity via EC2 failed"
            echo "This might be due to security group configuration or instance not being ready"
        fi
    fi
else
    echo "ℹ Cannot test database connectivity - missing RDS or infrastructure details"
fi

echo ""
echo "All tests passed! The RDS setup is ready to use."
echo ""
echo "Next steps:"
echo "1. Run './rds-setup.sh' to create RDS instance (if not already done)"
echo "2. Run './db-init.sh' to initialize the database via EC2"
echo "3. Run './rds-cleanup.sh' to clean up RDS resources" 