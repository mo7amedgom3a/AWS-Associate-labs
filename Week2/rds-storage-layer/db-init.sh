#!/bin/bash

# Exit on error
set -e

# Database Initialization Script
# This script copies the dump file to EC2 instance and initializes the database via SSH

RDS_OUTPUT_FILE="rds-details.txt"
INIT_SQL_FILE="init.sql"
DUMP_FILE="mydb_dump.sql"
INFRASTRUCTURE_OUTPUT_FILE="../ec2-layer/aws_cli/infrastructure-details.txt"

echo "Initializing RDS MySQL database via EC2 instance..."

# Load RDS configuration
if [ -f "$RDS_OUTPUT_FILE" ]; then
    source "$RDS_OUTPUT_FILE"
    echo "Loaded RDS configuration from $RDS_OUTPUT_FILE"
else
    echo "Error: RDS configuration file not found."
    echo "Please run rds-setup.sh first to create the RDS instance."
    exit 1
fi

# Load infrastructure configuration for EC2 details
if [ -f "$INFRASTRUCTURE_OUTPUT_FILE" ]; then
    source "$INFRASTRUCTURE_OUTPUT_FILE"
    echo "Loaded infrastructure configuration from $INFRASTRUCTURE_OUTPUT_FILE"
else
    echo "Error: Infrastructure configuration file not found."
    echo "Please run ../ec2-layer/aws_cli/setup.sh first to create the EC2 instance."
    exit 1
fi

# Check if required variables are loaded
if [ -z "$DB_ENDPOINT" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Required database configuration variables are missing."
    echo "Please run rds-setup.sh first to create the RDS instance."
    exit 1
fi

if [ -z "$EC2_PUBLIC_IP" ] || [ -z "$SSH_COMMAND" ]; then
    echo "Error: Required EC2 configuration variables are missing."
    echo "Please run ../ec2-layer/aws_cli/setup.sh first to create the EC2 instance."
    exit 1
fi

# Check if SQL files exist
if [ ! -f "$INIT_SQL_FILE" ]; then
    echo "Error: $INIT_SQL_FILE file not found."
    exit 1
fi

if [ ! -f "$DUMP_FILE" ]; then
    echo "Warning: $DUMP_FILE file not found. Will use $INIT_SQL_FILE instead."
    USE_DUMP_FILE=false
else
    USE_DUMP_FILE=true
fi

# Check if SSH key exists
SSH_KEY_PATH="~/aws_keys.pem"


# Wait for RDS instance to be available
echo "Checking RDS instance status..."
DB_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text 2>/dev/null || echo "not-found")

if [ "$DB_STATUS" != "available" ] && [ "$DB_STATUS" != "not-found" ]; then
    echo "RDS instance is not available. Current status: $DB_STATUS"
    echo "Waiting for instance to become available..."
    aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER 2>/dev/null || echo "Waiting for RDS instance to be available..."
elif [ "$DB_STATUS" == "not-found" ]; then
    echo "RDS instance not found. Please run rds-setup.sh first."
    exit 1
fi

echo "RDS instance is available. Connecting via EC2 instance..."

# Test EC2 connectivity
echo "Testing EC2 connectivity..."
if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "echo 'EC2 connection successful'" 2>/dev/null; then
    echo "✓ EC2 connection successful"
else
    echo "✗ EC2 connection failed"
    echo "Please check your EC2 instance status and SSH key configuration."
    exit 1
fi

# Install MySQL client on EC2 if not already installed
echo "Installing MySQL client on EC2 instance..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP << 'EOF'
if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL client..."
    sudo yum update -y
    sudo yum install -y mysql
else
    echo "MySQL client already installed"
fi
EOF

# Copy SQL files to EC2 instance
echo "Copying SQL files to EC2 instance..."
if [ "$USE_DUMP_FILE" = true ]; then
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$DUMP_FILE" ec2-user@$EC2_PUBLIC_IP:~/ 2>/dev/null || echo "Failed to copy dump file"
fi
scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$INIT_SQL_FILE" ec2-user@$EC2_PUBLIC_IP:~/ 2>/dev/null || echo "Failed to copy init file"

# Test database connection from EC2 instance
echo "Testing database connection from EC2 instance..."
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' -e 'SELECT 1;'" 2>/dev/null; then
        echo "✓ Database connection successful from EC2"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "✗ Database connection failed (attempt $RETRY_COUNT/$MAX_RETRIES)"
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "Retrying in 30 seconds..."
            sleep 30
        else
            echo "Failed to connect to database after $MAX_RETRIES attempts."
            echo "Please check your RDS instance status and security group configuration."
            exit 1
        fi
    fi
done

# Create database if it doesn't exist
echo "Creating database if it doesn't exist..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP << EOF
mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' -e 'CREATE DATABASE IF NOT EXISTS $DB_NAME;'
EOF

# Initialize database from EC2 instance
echo "Initializing database from EC2 instance..."
if [ "$USE_DUMP_FILE" = true ]; then
    echo "Using dump file: $DUMP_FILE"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP << EOF
mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' $DB_NAME < ~/$DUMP_FILE
EOF
    if [ $? -eq 0 ]; then
        echo "✓ Database initialization with dump file successful"
    else
        echo "⚠ Database initialization with dump file failed, trying init.sql..."
        ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP << EOF
mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' $DB_NAME < ~/$INIT_SQL_FILE
EOF
        if [ $? -eq 0 ]; then
            echo "✓ Database initialization with init.sql successful"
        else
            echo "✗ Database initialization failed"
        fi
    fi
else
    echo "Using init file: $INIT_SQL_FILE"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP << EOF
mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' $DB_NAME < ~/$INIT_SQL_FILE
EOF
    if [ $? -eq 0 ]; then
        echo "✓ Database initialization successful"
    else
        echo "✗ Database initialization failed"
    fi
fi

# Verify database initialization from EC2 instance
echo "Verifying database initialization from EC2 instance..."
if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' -e 'USE $DB_NAME; SHOW TABLES;'" 2>/dev/null; then
    echo "✓ Database verification successful"
    echo "Database tables created:"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' -e 'USE $DB_NAME; SHOW TABLES;'" 2>/dev/null || echo "Could not show tables"
    
    echo "Sample data inserted:"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "mysql -h '$DB_ENDPOINT' -P '$DB_PORT' -u '$DB_USERNAME' -p'$DB_PASSWORD' -e 'USE $DB_NAME; SELECT * FROM employees;'" 2>/dev/null || echo "Could not show sample data"
else
    echo "⚠ Database verification failed"
    echo "This might be because the database already exists or there's a connection issue."
    echo "You can manually verify the database connection from the EC2 instance."
fi

# Clean up SQL files from EC2 instance
echo "Cleaning up SQL files from EC2 instance..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no ec2-user@$EC2_PUBLIC_IP "rm -f ~/$INIT_SQL_FILE ~/$DUMP_FILE" 2>/dev/null || echo "Could not clean up SQL files"

echo ""
echo "Database initialization complete!"
echo "================================================"
echo "Database Endpoint: $DB_ENDPOINT"
echo "Database Port: $DB_PORT"
echo "Database Name: $DB_NAME"
echo "Database Username: $DB_USERNAME"
echo "EC2 Public IP: $EC2_PUBLIC_IP"
echo "================================================"
echo ""
echo "Connection string for Django:"
echo "mysql://$DB_USERNAME:$DB_PASSWORD@$DB_ENDPOINT:$DB_PORT/$DB_NAME"
echo ""
echo "To test the connection manually from EC2:"
echo "ssh -i $SSH_KEY_PATH ec2-user@$EC2_PUBLIC_IP"
echo "mysql -h $DB_ENDPOINT -P $DB_PORT -u $DB_USERNAME -p'$DB_PASSWORD' $DB_NAME" 