#!/bin/bash
set -e

# Variables
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.0.0/24"
PRIVATE_SUBNET_CIDR="10.0.2.0/24"
REGION="us-east-1"
KEY_NAME="aws_keys"
VPC_NAME="Lab VPC"
IGW_NAME="Lab Internet Gateway"
SG_NAME="LabWebSG"
OUTPUT_FILE="aws_resources.txt"

echo "=== Starting VPC Infrastructure Setup ==="

# Initialize output file
echo "AWS Resources Created - $(date)" > $OUTPUT_FILE
echo "========================================" >> $OUTPUT_FILE

# 1. Create VPC
echo "Step 1: Checking/Creating VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" "Name=state,Values=available" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")

if [ "$VPC_ID" = "None" ] || [ "$VPC_ID" = "null" ]; then
    echo "  Creating new VPC with CIDR $VPC_CIDR..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value="$VPC_NAME"
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
    echo "  VPC created: $VPC_ID"
    echo "VPC_ID=$VPC_ID" >> $OUTPUT_FILE
else
    echo "  VPC already exists: $VPC_ID"
    echo "VPC_ID=$VPC_ID (existing)" >> $OUTPUT_FILE
fi

# 2. Create Internet Gateway and attach to VPC
echo "Step 2: Checking/Creating Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=$IGW_NAME" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || echo "None")

if [ "$IGW_ID" = "None" ] || [ "$IGW_ID" = "null" ]; then
    echo "  Creating new Internet Gateway..."
    IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value="$IGW_NAME"
    echo "  Internet Gateway created: $IGW_ID"
    echo "IGW_ID=$IGW_ID" >> $OUTPUT_FILE
else
    echo "  Internet Gateway already exists: $IGW_ID"
    echo "IGW_ID=$IGW_ID (existing)" >> $OUTPUT_FILE
fi

# Check if IGW is attached to VPC
echo "  Checking Internet Gateway attachment..."
IGW_ATTACHED=$(aws ec2 describe-internet-gateways --internet-gateway-ids $IGW_ID --query "InternetGateways[0].Attachments[?VpcId=='$VPC_ID'].State" --output text 2>/dev/null || echo "None")

if [ "$IGW_ATTACHED" != "available" ]; then
    echo "  Attaching Internet Gateway to VPC..."
    aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    echo "  Internet Gateway attached to VPC"
else
    echo "  Internet Gateway already attached to VPC"
fi

# 3. Create Subnets
echo "Step 3: Checking/Creating Subnets..."

# Public Subnet
PUB_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Public Subnet" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "None")

if [ "$PUB_SUBNET_ID" = "None" ] || [ "$PUB_SUBNET_ID" = "null" ]; then
    echo "  Creating Public Subnet with CIDR $PUBLIC_SUBNET_CIDR..."
    PUB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_CIDR --availability-zone ${REGION}a --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $PUB_SUBNET_ID --tags Key=Name,Value="Public Subnet"
    aws ec2 modify-subnet-attribute --subnet-id $PUB_SUBNET_ID --map-public-ip-on-launch
    echo "  Public Subnet created: $PUB_SUBNET_ID"
    echo "PUBLIC_SUBNET_ID=$PUB_SUBNET_ID" >> $OUTPUT_FILE
else
    echo "  Public Subnet already exists: $PUB_SUBNET_ID"
    echo "PUBLIC_SUBNET_ID=$PUB_SUBNET_ID (existing)" >> $OUTPUT_FILE
fi

# Private Subnet
PRIV_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Private Subnet" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "None")

if [ "$PRIV_SUBNET_ID" = "None" ] || [ "$PRIV_SUBNET_ID" = "null" ]; then
    echo "  Creating Private Subnet with CIDR $PRIVATE_SUBNET_CIDR..."
    PRIV_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIVATE_SUBNET_CIDR --availability-zone ${REGION}b --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $PRIV_SUBNET_ID --tags Key=Name,Value="Private Subnet"
    echo "  Private Subnet created: $PRIV_SUBNET_ID"
    echo "PRIVATE_SUBNET_ID=$PRIV_SUBNET_ID" >> $OUTPUT_FILE
else
    echo "  Private Subnet already exists: $PRIV_SUBNET_ID"
    echo "PRIVATE_SUBNET_ID=$PRIV_SUBNET_ID (existing)" >> $OUTPUT_FILE
fi

# 4. Create Route Table and associate with Public Subnet
echo "Step 4: Checking/Creating Route Table..."
RTB_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=Public Route Table" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || echo "None")

if [ "$RTB_ID" = "None" ] || [ "$RTB_ID" = "null" ]; then
    echo "  Creating Public Route Table..."
    RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
    aws ec2 create-tags --resources $RTB_ID --tags Key=Name,Value="Public Route Table"
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
    aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id $PUB_SUBNET_ID
    echo "  Route Table created and associated: $RTB_ID"
    echo "ROUTE_TABLE_ID=$RTB_ID" >> $OUTPUT_FILE
else
    echo "  Route Table already exists: $RTB_ID"
    echo "ROUTE_TABLE_ID=$RTB_ID (existing)" >> $OUTPUT_FILE
    # Check if route and association exist
    ROUTE_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" --output text 2>/dev/null || echo "None")
    if [ "$ROUTE_EXISTS" = "None" ] || [ "$ROUTE_EXISTS" = "" ]; then
        echo "  Adding route to Internet Gateway..."
        aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
    fi
    
    ASSOC_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query "RouteTables[0].Associations[?SubnetId=='$PUB_SUBNET_ID'].SubnetId" --output text 2>/dev/null || echo "None")
    if [ "$ASSOC_EXISTS" = "None" ] || [ "$ASSOC_EXISTS" = "" ]; then
        echo "  Associating Route Table with Public Subnet..."
        aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id $PUB_SUBNET_ID
    fi
fi

# 5. Create Security Group
echo "Step 5: Checking/Creating Security Group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [ "$SG_ID" = "None" ] || [ "$SG_ID" = "null" ]; then
    echo "  Creating Security Group..."
    SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" --description "Allow HTTP, HTTPS, SSH" --vpc-id $VPC_ID --query 'GroupId' --output text)
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
    echo "  Security Group created: $SG_ID"
    echo "SECURITY_GROUP_ID=$SG_ID" >> $OUTPUT_FILE
else
    echo "  Security Group already exists: $SG_ID"
    echo "SECURITY_GROUP_ID=$SG_ID (existing)" >> $OUTPUT_FILE
fi

# 6. Launch EC2 Instance with User Data
echo "Step 6: Checking/Creating EC2 Instance..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Lab Web Server" "Name=instance-state-name,Values=running,pending" --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || echo "None")

if [ "$INSTANCE_ID" = "None" ] || [ "$INSTANCE_ID" = "null" ]; then
    echo "  Creating EC2 Instance..."
    AMI_ID="ami-00ca32bbc84273381" # Amazon Linux 2023 AMI (us-east-1)
    USER_DATA=$(base64 -w 0 <<'EOF'
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
cat > /var/www/html/index.html << EOT
<!DOCTYPE html>
<html>
<head>
     <title>Hello World</title>
</head>
<body>
     <h1>Welcome to Hello World</h1>
     <p>This server is running in the public subnet of our VPC.</p>
     <p>Server IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
</body>
</html>
EOT
chown nginx:nginx /var/www/html/index.html
chmod 644 /var/www/html/index.html
systemctl restart nginx
EOF
)

    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id $AMI_ID \
      --count 1 \
      --instance-type t2.micro \
      --key-name $KEY_NAME \
      --subnet-id $PUB_SUBNET_ID \
      --security-group-ids $SG_ID \
      --associate-public-ip-address \
      --user-data $USER_DATA \
      --query 'Instances[0].InstanceId' \
      --output text)

    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value="Lab Web Server"
    echo "  EC2 Instance created: $INSTANCE_ID"
    echo "EC2_INSTANCE_ID=$INSTANCE_ID" >> $OUTPUT_FILE
else
    echo "  EC2 Instance already exists: $INSTANCE_ID"
    echo "EC2_INSTANCE_ID=$INSTANCE_ID (existing)" >> $OUTPUT_FILE
fi

# 7. Output EC2 Public IP
echo "Step 7: Retrieving EC2 Public IP..."
echo "  Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "  EC2 Public IP: $EC2_PUBLIC_IP"
echo "EC2_PUBLIC_IP=$EC2_PUBLIC_IP" >> $OUTPUT_FILE

# Write completion timestamp
echo "COMPLETED=$(date)" >> $OUTPUT_FILE

echo "=== VPC Infrastructure Setup Complete ==="
echo "Summary:"
echo "  VPC ID: $VPC_ID"
echo "  Internet Gateway ID: $IGW_ID"
echo "  Public Subnet ID: $PUB_SUBNET_ID"
echo "  Private Subnet ID: $PRIV_SUBNET_ID"
echo "  Route Table ID: $RTB_ID"
echo "  Security Group ID: $SG_ID"
echo "  EC2 Instance ID: $INSTANCE_ID"
echo "  EC2 Public IP: $EC2_PUBLIC_IP"
echo "=== Resource IDs saved to: $OUTPUT_FILE ==="
echo "=== Access your web server at: http://$EC2_PUBLIC_IP ==="