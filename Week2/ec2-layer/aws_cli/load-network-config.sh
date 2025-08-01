#!/bin/bash

# Network Configuration Loader Script
# This script loads network configuration details from the network-details.txt file

NETWORK_OUTPUT_FILE="network-details.txt"

# Function to load network configuration
load_network_config() {
    if [ -f "$NETWORK_OUTPUT_FILE" ]; then
        echo "Loading network configuration from $NETWORK_OUTPUT_FILE..."
        source "$NETWORK_OUTPUT_FILE"
        
        # Validate that required variables are loaded
        if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ] || [ -z "$SECURITY_GROUP_ID" ]; then
            echo "Error: Required network configuration variables are missing."
            echo "Please run network-setup.sh first to create the network infrastructure."
            exit 1
        fi
        
        echo "Network configuration loaded successfully:"
        echo "  VPC ID: $VPC_ID"
        echo "  Subnet ID: $SUBNET_ID"
        echo "  Security Group ID: $SECURITY_GROUP_ID"
        echo "  Route Table ID: $ROUTE_TABLE_ID"
        echo "  Internet Gateway ID: $IGW_ID"
        
        # Export variables for use in other scripts
        export VPC_ID
        export SUBNET_ID
        export SECURITY_GROUP_ID
        export ROUTE_TABLE_ID
        export IGW_ID
        export AWS_REGION
        export PROJECT_NAME
        export ENVIRONMENT
        
        return 0
    else
        echo "Error: Network configuration file $NETWORK_OUTPUT_FILE not found."
        echo "Please run network-setup.sh first to create the network infrastructure."
        return 1
    fi
}

# Function to check if network infrastructure exists
check_network_exists() {
    if [ -f "$NETWORK_OUTPUT_FILE" ]; then
        source "$NETWORK_OUTPUT_FILE"
        
        # Check if VPC exists
        if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].VpcId' --output text 2>/dev/null | grep -q "$VPC_ID"; then
            echo "Network infrastructure exists and is valid."
            return 0
        else
            echo "Warning: Network infrastructure may not exist or may be invalid."
            return 1
        fi
    else
        echo "Network configuration file not found."
        return 1
    fi
}

# If script is sourced, load configuration automatically
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    load_network_config
fi 