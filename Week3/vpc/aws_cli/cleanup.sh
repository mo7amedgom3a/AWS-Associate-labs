#!/bin/bash
set -e

RESOURCE_FILE="aws_resources.txt"

# Helper to extract value by key
get_value() {
    grep "^$1=" "$RESOURCE_FILE" | head -n1 | cut -d'=' -f2 | awk '{print $1}'
}

echo "=== Starting AWS Resource Cleanup ==="

# 1. Terminate EC2 Instance
INSTANCE_ID=$(get_value EC2_INSTANCE_ID)
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "(existing)" ]; then
    echo "Terminating EC2 instance: $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
else
    echo "No EC2 instance to terminate or instance is marked as existing."
fi

# 2. Delete Security Group
SG_ID=$(get_value SECURITY_GROUP_ID)
if [ -n "$SG_ID" ] && [ "$SG_ID" != "(existing)" ]; then
    echo "Deleting Security Group: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID || echo "Security group may be in use or already deleted."
else
    echo "No Security Group to delete or group is marked as existing."
fi

# 3. Disassociate and delete Route Table
RTB_ID=$(get_value ROUTE_TABLE_ID)
if [ -n "$RTB_ID" ] && [ "$RTB_ID" != "(existing)" ]; then
    echo "Deleting Route Table: $RTB_ID"
    # Disassociate all associations
    ASSOC_IDS=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query "RouteTables[0].Associations[].RouteTableAssociationId" --output text)
    for ASSOC_ID in $ASSOC_IDS; do
        aws ec2 disassociate-route-table --association-id $ASSOC_ID || true
    done
    aws ec2 delete-route-table --route-table-id $RTB_ID
else
    echo "No Route Table to delete or table is marked as existing."
fi

# 4. Delete Subnets
PUB_SUBNET_ID=$(get_value PUBLIC_SUBNET_ID)
if [ -n "$PUB_SUBNET_ID" ] && [ "$PUB_SUBNET_ID" != "(existing)" ]; then
    echo "Deleting Public Subnet: $PUB_SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $PUB_SUBNET_ID
else
    echo "No Public Subnet to delete or subnet is marked as existing."
fi

PRIV_SUBNET_ID=$(get_value PRIVATE_SUBNET_ID)
if [ -n "$PRIV_SUBNET_ID" ] && [ "$PRIV_SUBNET_ID" != "(existing)" ]; then
    echo "Deleting Private Subnet: $PRIV_SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $PRIV_SUBNET_ID
else
    echo "No Private Subnet to delete or subnet is marked as existing."
fi

# 5. Detach and delete Internet Gateway
IGW_ID=$(get_value IGW_ID)
VPC_ID=$(get_value VPC_ID)
if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "(existing)" ] && [ -n "$VPC_ID" ] && [ "$VPC_ID" != "(existing)" ]; then
    echo "Detaching Internet Gateway: $IGW_ID from VPC: $VPC_ID"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID || true
    echo "Deleting Internet Gateway: $IGW_ID"
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
else
    echo "No Internet Gateway to delete or gateway/VPC is marked as existing."
fi

# 6. Delete VPC
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "(existing)" ]; then
    echo "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id $VPC_ID
else
    echo "No VPC to delete or VPC is marked as existing."
fi

echo "=== AWS Resource Cleanup Complete ==="