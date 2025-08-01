#!/bin/bash

# Exit on error
set -e

# RDS Infrastructure Cleanup Script
# This script removes RDS instance and related network components

RDS_OUTPUT_FILE="rds-details.txt"
NETWORK_OUTPUT_FILE="../ec2-layer/aws_cli/network-details.txt"

echo "Starting RDS infrastructure cleanup..."

# Load RDS configuration if available
if [ -f "$RDS_OUTPUT_FILE" ]; then
    source "$RDS_OUTPUT_FILE"
    echo "Loaded RDS configuration from $RDS_OUTPUT_FILE"
else
    echo "RDS configuration file not found. Attempting to find resources by tags..."
    
    # Try to find resources by project tags
    PROJECT_NAME="django-web-app"
    
    # Find RDS instance by project tag
    DB_INSTANCE_IDENTIFIER=$(aws rds describe-db-instances \
        --query 'DBInstances[?contains(TagList[?Key==`Project`].Value, `'$PROJECT_NAME'`)].DBInstanceIdentifier' \
        --output text 2>/dev/null || echo "")
    
    if [ "$DB_INSTANCE_IDENTIFIER" != "None" ] && [ "$DB_INSTANCE_IDENTIFIER" != "" ] && [ "$DB_INSTANCE_IDENTIFIER" != "null" ]; then
        echo "Found RDS instance: $DB_INSTANCE_IDENTIFIER"
        
        # Get RDS details
        DB_ENDPOINT=$(aws rds describe-db-instances \
            --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text 2>/dev/null || echo "")
        DB_PORT=$(aws rds describe-db-instances \
            --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
            --query 'DBInstances[0].Endpoint.Port' \
            --output text 2>/dev/null || echo "")
        
        # Find DB subnet group
        DB_SUBNET_GROUP_NAME=$(aws rds describe-db-instances \
            --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
            --query 'DBInstances[0].DBSubnetGroup.DBSubnetGroupName' \
            --output text 2>/dev/null || echo "")
        
        # Find security group
        RDS_SECURITY_GROUP_ID=$(aws rds describe-db-instances \
            --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
            --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
            --output text 2>/dev/null || echo "")
    else
        echo "No RDS instance found with project tag $PROJECT_NAME"
        # Continue with cleanup in case there are orphaned resources
    fi
fi

# Load network configuration for private subnet cleanup
if [ -f "$NETWORK_OUTPUT_FILE" ]; then
    source "$NETWORK_OUTPUT_FILE"
    echo "Loaded network configuration for cleanup"
else
    echo "Warning: Network configuration file not found. Private subnet cleanup may fail."
fi

# Cleanup in reverse order of creation

# 1. Delete RDS instance
if [ ! -z "$DB_INSTANCE_IDENTIFIER" ] && [ "$DB_INSTANCE_IDENTIFIER" != "None" ] && [ "$DB_INSTANCE_IDENTIFIER" != "null" ]; then
    echo "Checking RDS instance status..."
    DB_STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    if [ "$DB_STATUS" != "None" ] && [ "$DB_STATUS" != "" ] && [ "$DB_STATUS" != "null" ] && [ "$DB_STATUS" != "not-found" ]; then
        echo "RDS instance status: $DB_STATUS"
        
        if [ "$DB_STATUS" == "available" ]; then
            echo "Deleting RDS instance: $DB_INSTANCE_IDENTIFIER"
            aws rds delete-db-instance \
                --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
                --skip-final-snapshot \
                --delete-automated-backups 2>/dev/null || echo "Failed to delete RDS instance"
            
            echo "Waiting for RDS instance to be deleted..."
            aws rds wait db-instance-deleted --db-instance-identifier $DB_INSTANCE_IDENTIFIER 2>/dev/null || echo "RDS instance deletion completed"
            echo "RDS instance deleted successfully"
        else
            echo "RDS instance is not in 'available' state. Current status: $DB_STATUS"
            echo "Please wait for the instance to be available before deletion."
            echo "Continuing with other cleanup tasks..."
        fi
    else
        echo "RDS instance $DB_INSTANCE_IDENTIFIER not found or already deleted"
    fi
else
    echo "No RDS instance identifier found, skipping RDS deletion"
fi

# 2. Delete DB subnet group
if [ ! -z "$DB_SUBNET_GROUP_NAME" ] && [ "$DB_SUBNET_GROUP_NAME" != "None" ] && [ "$DB_SUBNET_GROUP_NAME" != "null" ]; then
    echo "Deleting DB subnet group: $DB_SUBNET_GROUP_NAME"
    aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP_NAME 2>/dev/null || echo "DB subnet group already deleted or not found"
else
    echo "No DB subnet group found, skipping deletion"
fi

# 3. Delete RDS security group rules
if [ ! -z "$RDS_SECURITY_GROUP_ID" ] && [ "$RDS_SECURITY_GROUP_ID" != "None" ] && [ "$RDS_SECURITY_GROUP_ID" != "null" ]; then
    echo "Removing RDS security group rules..."
    aws ec2 revoke-security-group-ingress \
        --group-id $RDS_SECURITY_GROUP_ID \
        --protocol tcp \
        --port 3306 \
        --source-group $SECURITY_GROUP_ID 2>/dev/null || echo "Security group rule already removed or not found"
else
    echo "No RDS security group found, skipping rule removal"
fi

# 4. Delete RDS security group
if [ ! -z "$RDS_SECURITY_GROUP_ID" ] && [ "$RDS_SECURITY_GROUP_ID" != "None" ] && [ "$RDS_SECURITY_GROUP_ID" != "null" ]; then
    echo "Deleting RDS security group: $RDS_SECURITY_GROUP_ID"
    aws ec2 delete-security-group --group-id $RDS_SECURITY_GROUP_ID 2>/dev/null || echo "RDS security group already deleted or not found"
else
    echo "No RDS security group found, skipping deletion"
fi

# 5. Clean up private subnet and route table (if network config is available)
if [ ! -z "$VPC_ID" ] && [ ! -z "$PRIVATE_SUBNET_ID" ]; then
    # Disassociate private route table from private subnet
    if [ ! -z "$PRIVATE_ROUTE_TABLE_ID" ] && [ "$PRIVATE_ROUTE_TABLE_ID" != "None" ] && [ "$PRIVATE_ROUTE_TABLE_ID" != "null" ]; then
        echo "Disassociating private route table from private subnet..."
        ASSOCIATION_ID=$(aws ec2 describe-route-tables \
            --route-table-ids $PRIVATE_ROUTE_TABLE_ID \
            --query 'RouteTables[0].Associations[?SubnetId==`'$PRIVATE_SUBNET_ID'`].RouteTableAssociationId' \
            --output text 2>/dev/null || echo "")
        
        if [ ! -z "$ASSOCIATION_ID" ] && [ "$ASSOCIATION_ID" != "None" ] && [ "$ASSOCIATION_ID" != "null" ]; then
            aws ec2 disassociate-route-table --association-id $ASSOCIATION_ID 2>/dev/null || echo "Route table already disassociated"
        fi
        
        # Delete private route table
        echo "Deleting private route table: $PRIVATE_ROUTE_TABLE_ID"
        aws ec2 delete-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID 2>/dev/null || echo "Private route table already deleted or not found"
    else
        echo "No private route table found, skipping deletion"
    fi
    
    # Delete private subnet
    echo "Deleting private subnet: $PRIVATE_SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID 2>/dev/null || echo "Private subnet already deleted or not found"
else
    echo "No VPC or private subnet information found, skipping subnet cleanup"
fi

# Remove RDS configuration file
if [ -f "$RDS_OUTPUT_FILE" ]; then
    rm "$RDS_OUTPUT_FILE"
    echo "Removed RDS configuration file: $RDS_OUTPUT_FILE"
else
    echo "RDS configuration file not found, nothing to remove"
fi

echo "RDS infrastructure cleanup complete!" 