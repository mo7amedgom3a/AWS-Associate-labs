#!/bin/bash

# Set permissions for scripts
chmod +x setup.sh
chmod +x cleanup.sh
chmod +x test.sh

echo "AWS CLI scripts are now executable."
echo ""
echo "Available commands:"
echo "  ./setup.sh    - Create the EC2 instance and ECR repository"
echo "  ./test.sh     - Test the connectivity to created resources"
echo "  ./cleanup.sh  - Delete all created resources"

# AWS Infrastructure Setup Scripts

This directory contains modular scripts for setting up AWS infrastructure for a Django web application.

## Script Overview

### Core Scripts

1. **`setup.sh`** - Main infrastructure setup script
   - Creates EC2 instances, ECR repositories, and key pairs
   - Uses network configuration from `network-setup.sh`
   - Generates `infrastructure-details.txt` with all resource details

2. **`network-setup.sh`** - Network infrastructure setup
   - Creates VPC, subnets, internet gateway, route tables, and security groups
   - Generates `network-details.txt` with network resource IDs
   - Can be run independently or called by `setup.sh`

3. **`network-cleanup.sh`** - Network infrastructure cleanup
   - Removes all network components in the correct order
   - Handles dependencies and safety checks
   - Removes `network-details.txt` file

### Utility Scripts

4. **`load-network-config.sh`** - Network configuration loader
   - Utility script to load network configuration from `network-details.txt`
   - Can be sourced by other scripts: `source load-network-config.sh`
   - Includes validation and error handling

5. **`cleanup.sh`** - General cleanup script
   - Removes EC2 instances and other resources
   - Works with the modular network setup

## Usage

### Quick Start (All-in-One)
```bash
./setup.sh
```
This will:
1. Create network infrastructure if it doesn't exist
2. Create EC2 instance and ECR repository
3. Generate configuration files

### Step-by-Step Setup

1. **Create Network Infrastructure:**
   ```bash
   ./network-setup.sh
   ```

2. **Create Application Infrastructure:**
   ```bash
   ./setup.sh
   ```

### Cleanup

1. **Clean up everything:**
   ```bash
   ./cleanup.sh
   ./network-cleanup.sh
   ```

2. **Clean up only network:**
   ```bash
   ./network-cleanup.sh
   ```

## Configuration Files

- **`network-details.txt`** - Contains network resource IDs (VPC, subnet, security group, etc.)
- **`infrastructure-details.txt`** - Contains all infrastructure details including EC2 and ECR information

## Benefits of Modular Design

1. **Separation of Concerns** - Network and application infrastructure are managed separately
2. **Reusability** - Network infrastructure can be reused for multiple applications
3. **Maintainability** - Easier to modify and debug individual components
4. **Flexibility** - Can create network once and deploy multiple applications
5. **Safety** - Network cleanup includes dependency checks and safety prompts

## Network Components Created

- **VPC** with CIDR block 10.0.0.0/16
- **Public Subnet** in us-east-1a with CIDR 10.0.1.0/24
- **Internet Gateway** attached to VPC
- **Route Table** with route to internet gateway
- **Security Group** with rules for ports 22, 80, 443, and 8000

## Security Notes

- SSH access (port 22) is open to 0.0.0.0/0 for development
- Web ports (80, 443, 8000) are open to 0.0.0.0/0
- Consider restricting access in production environments

## Prerequisites

- AWS CLI configured with appropriate permissions
- Bash shell environment
- AWS region set to us-east-1 (modify in scripts if needed)
