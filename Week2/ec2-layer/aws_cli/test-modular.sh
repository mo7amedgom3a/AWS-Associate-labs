#!/bin/bash

# Test script for modular network setup
# This script tests the network configuration loading and validation

echo "Testing modular network setup..."

# Test 1: Check if network-setup.sh exists and is executable
if [ -x "./network-setup.sh" ]; then
    echo "✓ network-setup.sh exists and is executable"
else
    echo "✗ network-setup.sh is missing or not executable"
    exit 1
fi

# Test 2: Check if load-network-config.sh exists and is executable
if [ -x "./load-network-config.sh" ]; then
    echo "✓ load-network-config.sh exists and is executable"
else
    echo "✗ load-network-config.sh is missing or not executable"
    exit 1
fi

# Test 3: Check if network-cleanup.sh exists and is executable
if [ -x "./network-cleanup.sh" ]; then
    echo "✓ network-cleanup.sh exists and is executable"
else
    echo "✗ network-cleanup.sh is missing or not executable"
    exit 1
fi

# Test 4: Test network configuration loading (if network-details.txt exists)
if [ -f "network-details.txt" ]; then
    echo "Testing network configuration loading..."
    
    # Source the load-network-config script
    source ./load-network-config.sh
    
    # Check if required variables are set
    if [ ! -z "$VPC_ID" ] && [ ! -z "$SUBNET_ID" ] && [ ! -z "$SECURITY_GROUP_ID" ]; then
        echo "✓ Network configuration loaded successfully"
        echo "  VPC ID: $VPC_ID"
        echo "  Subnet ID: $SUBNET_ID"
        echo "  Security Group ID: $SECURITY_GROUP_ID"
    else
        echo "✗ Failed to load network configuration"
        exit 1
    fi
else
    echo "ℹ network-details.txt not found - run ./network-setup.sh first"
fi

# Test 5: Test AWS CLI connectivity
echo "Testing AWS CLI connectivity..."
if aws sts get-caller-identity --query 'Account' --output text > /dev/null 2>&1; then
    echo "✓ AWS CLI is configured and working"
else
    echo "✗ AWS CLI is not configured or not working"
    exit 1
fi

# Test 6: Test if we can describe VPCs (basic permission check)
if aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text > /dev/null 2>&1; then
    echo "✓ AWS EC2 permissions are working"
else
    echo "✗ AWS EC2 permissions are not working"
    exit 1
fi

echo ""
echo "All tests passed! The modular network setup is ready to use."
echo ""
echo "Next steps:"
echo "1. Run './network-setup.sh' to create network infrastructure"
echo "2. Run './setup.sh' to create EC2 instance and ECR repository"
echo "3. Run './cleanup.sh' and './network-cleanup.sh' to clean up" 