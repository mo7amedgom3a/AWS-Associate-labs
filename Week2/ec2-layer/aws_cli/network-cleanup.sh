#!/bin/bash

# Exit on error
set -e

# Network Infrastructure Cleanup Script
# This script removes all network components for the Django web application

NETWORK_OUTPUT_FILE="network-details.txt"

echo "Starting network infrastructure cleanup..."

# Load network configuration if available
if [ -f "$NETWORK_OUTPUT_FILE" ]; then
    source "$NETWORK_OUTPUT_FILE"
    echo "Loaded network configuration from $NETWORK_OUTPUT_FILE"
else
    echo "Network configuration file not found. Attempting to find resources by tags..."
    
    # Try to find resources by project tags
    PROJECT_NAME="django-web-app"
    
    # Find VPC by project tag
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        echo "Found VPC: $VPC_ID"
        
        # Find subnet
        SUBNET_ID=$(aws ec2 describe-subnets \
            --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Project,Values=$PROJECT_NAME" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        # Find security group
        SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
            --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=django-web-sg" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        # Find route table
        ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
            --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Project,Values=$PROJECT_NAME" \
            --query 'RouteTables[0].RouteTableId' \
            --output text 2>/dev/null)
        
        # Find internet gateway
        IGW_ID=$(aws ec2 describe-internet-gateways \
            --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text 2>/dev/null)
    else
        echo "No VPC found with project tag $PROJECT_NAME"
        exit 0
    fi
fi

# Check if there are any EC2 instances in the VPC
if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,pending,stopping" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text 2>/dev/null)
    
    if [ ! -z "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
        echo "Warning: Found running EC2 instances in VPC $VPC_ID:"
        echo "$INSTANCES"
        echo "Please terminate these instances before cleaning up the network."
        read -p "Do you want to continue with network cleanup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Network cleanup cancelled."
            exit 1
        fi
    fi
fi

# Cleanup in reverse order of creation

# 1. Delete security group rules (if security group exists)
if [ ! -z "$SECURITY_GROUP_ID" ] && [ "$SECURITY_GROUP_ID" != "None" ]; then
    echo "Removing security group rules..."
    aws ec2 revoke-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 2>/dev/null || true
    
    aws ec2 revoke-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 2>/dev/null || true
    
    aws ec2 revoke-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 8000 \
        --cidr 0.0.0.0/0 2>/dev/null || true
    
    aws ec2 revoke-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 2>/dev/null || true
fi

# 2. Delete security group
if [ ! -z "$SECURITY_GROUP_ID" ] && [ "$SECURITY_GROUP_ID" != "None" ]; then
    echo "Deleting security group: $SECURITY_GROUP_ID"
    aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID 2>/dev/null || echo "Security group already deleted or not found"
fi

# 3. Disassociate route table from subnet
if [ ! -z "$ROUTE_TABLE_ID" ] && [ ! -z "$SUBNET_ID" ] && [ "$ROUTE_TABLE_ID" != "None" ] && [ "$SUBNET_ID" != "None" ]; then
    echo "Disassociating route table from subnet..."
    ASSOCIATION_ID=$(aws ec2 describe-route-tables \
        --route-table-ids $ROUTE_TABLE_ID \
        --query 'RouteTables[0].Associations[?SubnetId==`'$SUBNET_ID'`].RouteTableAssociationId' \
        --output text 2>/dev/null)
    
    if [ ! -z "$ASSOCIATION_ID" ] && [ "$ASSOCIATION_ID" != "None" ]; then
        aws ec2 disassociate-route-table --association-id $ASSOCIATION_ID 2>/dev/null || true
    fi
fi

# 4. Delete route table
if [ ! -z "$ROUTE_TABLE_ID" ] && [ "$ROUTE_TABLE_ID" != "None" ]; then
    echo "Deleting route table: $ROUTE_TABLE_ID"
    aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID 2>/dev/null || echo "Route table already deleted or not found"
fi

# 5. Delete subnet
if [ ! -z "$SUBNET_ID" ] && [ "$SUBNET_ID" != "None" ]; then
    echo "Deleting subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $SUBNET_ID 2>/dev/null || echo "Subnet already deleted or not found"
fi

# 6. Detach and delete internet gateway
if [ ! -z "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
    echo "Detaching internet gateway: $IGW_ID"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 2>/dev/null || echo "Internet gateway already detached or not found"
    
    echo "Deleting internet gateway: $IGW_ID"
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID 2>/dev/null || echo "Internet gateway already deleted or not found"
fi

# 7. Delete VPC
if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null || echo "VPC already deleted or not found"
fi

# Remove network configuration file
if [ -f "$NETWORK_OUTPUT_FILE" ]; then
    rm "$NETWORK_OUTPUT_FILE"
    echo "Removed network configuration file: $NETWORK_OUTPUT_FILE"
fi

echo "Network infrastructure cleanup complete!" 