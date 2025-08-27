#!/bin/bash
# ================================
# EC2 Auto Scaling + CloudWatch Setup
# ================================

# ---- Variables (change these) ----
AMI_ID="ami-00ca32bbc84273381"                # Your AMI ID
INSTANCE_TYPE="t2.micro"             # Instance type
KEY_NAME="aws_keys"                # Existing key pair
SECURITY_GROUP_ID="ssh-security-group"      # Security group
SUBNET_ID="subnet-0b1cd5c1da71a79f4"          # Subnet where instances will launch
ASG_NAME="my-asg"
LT_NAME="my-templet-web-server"
REGION="us-east-1"                   # Change if needed
MIN_SIZE=1
MAX_SIZE=3
DESIRED_CAPACITY=1
CPU_THRESHOLD=50                     # CPU threshold %

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
RESOURCE_FILE="asg-resources.txt"

# Initialize resource file
echo "# Auto Scaling Group Resources" > $RESOURCE_FILE
echo "ACCOUNT_ID=$ACCOUNT_ID" >> $RESOURCE_FILE
echo "REGION=$REGION" >> $RESOURCE_FILE

echo "==> Starting Auto Scaling Group setup..."
echo "==> Resource IDs will be saved to: $RESOURCE_FILE"

# Check and create Launch Template
echo "==> Checking for existing Launch Template '$LT_NAME'..."
LT_ID=$(aws ec2 describe-launch-templates \
    --launch-template-names $LT_NAME \
    --query 'LaunchTemplates[0].LaunchTemplateId' \
    --output text 2>/dev/null)

if [ "$LT_ID" = "None" ] || [ -z "$LT_ID" ]; then
    echo "==> Launch Template not found. Creating new one..."
    LT_ID=$(aws ec2 create-launch-template \
        --launch-template-name $LT_NAME \
        --version-description "v1" \
        --launch-template-data "{
            \"ImageId\": \"$AMI_ID\",
            \"InstanceType\": \"$INSTANCE_TYPE\",
            \"KeyName\": \"$KEY_NAME\",
            \"UserData\": \"$(cat user_data.txt | base64 -w 0)\",
            \"SecurityGroupIds\": [\"$SECURITY_GROUP_ID\"]
        }" \
        --query 'LaunchTemplate.LaunchTemplateId' \
        --output text)
    
    if [ -z "$LT_ID" ]; then
        echo "ERROR: Failed to create Launch Template"
        exit 1
    fi
    echo "✓ Launch Template created successfully: $LT_ID"
else
    echo "✓ Launch Template already exists: $LT_ID"
fi

echo "LAUNCH_TEMPLATE_ID=$LT_ID" >> $RESOURCE_FILE
echo "LAUNCH_TEMPLATE_NAME=$LT_NAME" >> $RESOURCE_FILE

# Check and create Auto Scaling Group
echo "==> Checking for existing Auto Scaling Group '$ASG_NAME'..."
ASG_EXISTS=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names $ASG_NAME \
    --query 'AutoScalingGroups[0].AutoScalingGroupName' \
    --output text 2>/dev/null)

if [ "$ASG_EXISTS" = "None" ] || [ -z "$ASG_EXISTS" ]; then
    echo "==> Auto Scaling Group not found. Creating new one..."
    aws autoscaling create-auto-scaling-group \
        --auto-scaling-group-name $ASG_NAME \
        --launch-template "LaunchTemplateId=$LT_ID,Version=1" \
        --min-size $MIN_SIZE \
        --max-size $MAX_SIZE \
        --desired-capacity $DESIRED_CAPACITY \
        --vpc-zone-identifier $SUBNET_ID \
        --region $REGION
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create Auto Scaling Group"
        exit 1
    fi
    echo "✓ Auto Scaling Group created successfully: $ASG_NAME"
else
    echo "✓ Auto Scaling Group already exists: $ASG_NAME"
fi

echo "ASG_NAME=$ASG_NAME" >> $RESOURCE_FILE

# -----------------------------
# Create Scaling Policies
# -----------------------------
echo "==> Managing Scaling Policies..."

# Check and create Scale Out Policy
echo "==> Checking for existing Scale-Out Policy..."
SCALE_OUT_POLICY_ARN=$(aws autoscaling describe-policies \
    --auto-scaling-group-name $ASG_NAME \
    --policy-names cpu-scaleout-policy \
    --query 'ScalingPolicies[0].PolicyARN' \
    --output text 2>/dev/null)

if [ "$SCALE_OUT_POLICY_ARN" = "None" ] || [ -z "$SCALE_OUT_POLICY_ARN" ]; then
    echo "==> Creating Scale-Out Policy..."
    SCALE_OUT_POLICY_ARN=$(aws autoscaling put-scaling-policy \
        --auto-scaling-group-name $ASG_NAME \
        --policy-name cpu-scaleout-policy \
        --scaling-adjustment 1 \
        --adjustment-type ChangeInCapacity \
        --query 'PolicyARN' \
        --output text)
    
    if [ -z "$SCALE_OUT_POLICY_ARN" ]; then
        echo "ERROR: Failed to create Scale-Out Policy"
        exit 1
    fi
    echo "✓ Scale-Out Policy created: $SCALE_OUT_POLICY_ARN"
else
    echo "✓ Scale-Out Policy already exists: $SCALE_OUT_POLICY_ARN"
fi

echo "SCALE_OUT_POLICY_ARN=$SCALE_OUT_POLICY_ARN" >> $RESOURCE_FILE

# Check and create Scale In Policy
echo "==> Checking for existing Scale-In Policy..."
SCALE_IN_POLICY_ARN=$(aws autoscaling describe-policies \
    --auto-scaling-group-name $ASG_NAME \
    --policy-names cpu-scalein-policy \
    --query 'ScalingPolicies[0].PolicyARN' \
    --output text 2>/dev/null)

if [ "$SCALE_IN_POLICY_ARN" = "None" ] || [ -z "$SCALE_IN_POLICY_ARN" ]; then
    echo "==> Creating Scale-In Policy..."
    SCALE_IN_POLICY_ARN=$(aws autoscaling put-scaling-policy \
        --auto-scaling-group-name $ASG_NAME \
        --policy-name cpu-scalein-policy \
        --scaling-adjustment -1 \
        --adjustment-type ChangeInCapacity \
        --query 'PolicyARN' \
        --output text)
    
    if [ -z "$SCALE_IN_POLICY_ARN" ]; then
        echo "ERROR: Failed to create Scale-In Policy"
        exit 1
    fi
    echo "✓ Scale-In Policy created: $SCALE_IN_POLICY_ARN"
else
    echo "✓ Scale-In Policy already exists: $SCALE_IN_POLICY_ARN"
fi

echo "SCALE_IN_POLICY_ARN=$SCALE_IN_POLICY_ARN" >> $RESOURCE_FILE

# -----------------------------
# Create CloudWatch Alarms
# -----------------------------
echo "==> Managing CloudWatch Alarms..."

# Check and create Scale Out Alarm
echo "==> Checking for existing Scale-Out Alarm..."
SCALEOUT_ALARM_EXISTS=$(aws cloudwatch describe-alarms \
    --alarm-names cpu-scaleout-alarm \
    --query 'MetricAlarms[0].AlarmName' \
    --output text 2>/dev/null)

if [ "$SCALEOUT_ALARM_EXISTS" = "None" ] || [ -z "$SCALEOUT_ALARM_EXISTS" ]; then
    echo "==> Creating Scale-Out CloudWatch Alarm..."
    aws cloudwatch put-metric-alarm \
        --alarm-name cpu-scaleout-alarm \
        --metric-name CPUUtilization \
        --namespace AWS/EC2 \
        --statistic Average \
        --period 300 \
        --threshold $CPU_THRESHOLD \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=AutoScalingGroupName,Value=$ASG_NAME \
        --evaluation-periods 2 \
        --alarm-actions $SCALE_OUT_POLICY_ARN \
        --region $REGION
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create Scale-Out Alarm"
        exit 1
    fi
    echo "✓ Scale-Out Alarm created: cpu-scaleout-alarm"
else
    echo "✓ Scale-Out Alarm already exists: cpu-scaleout-alarm"
fi

echo "SCALEOUT_ALARM_NAME=cpu-scaleout-alarm" >> $RESOURCE_FILE

# Check and create Scale In Alarm
echo "==> Checking for existing Scale-In Alarm..."
SCALEIN_ALARM_EXISTS=$(aws cloudwatch describe-alarms \
    --alarm-names cpu-scalein-alarm \
    --query 'MetricAlarms[0].AlarmName' \
    --output text 2>/dev/null)

if [ "$SCALEIN_ALARM_EXISTS" = "None" ] || [ -z "$SCALEIN_ALARM_EXISTS" ]; then
    echo "==> Creating Scale-In CloudWatch Alarm..."
    aws cloudwatch put-metric-alarm \
        --alarm-name cpu-scalein-alarm \
        --metric-name CPUUtilization \
        --namespace AWS/EC2 \
        --statistic Average \
        --period 300 \
        --threshold $CPU_THRESHOLD \
        --comparison-operator LessThanThreshold \
        --dimensions Name=AutoScalingGroupName,Value=$ASG_NAME \
        --evaluation-periods 2 \
        --alarm-actions $SCALE_IN_POLICY_ARN \
        --region $REGION
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create Scale-In Alarm"
        exit 1
    fi
    echo "✓ Scale-In Alarm created: cpu-scalein-alarm"
else
    echo "✓ Scale-In Alarm already exists: cpu-scalein-alarm"
fi

echo "SCALEIN_ALARM_NAME=cpu-scalein-alarm" >> $RESOURCE_FILE

echo ""
echo "==> Setup Complete!"
echo "Auto Scaling Group '$ASG_NAME' is ready with CloudWatch monitoring."
echo "Resource IDs saved to: $RESOURCE_FILE"
echo ""
echo "Created/Verified Resources:"
echo "- Launch Template: $LT_ID"
echo "- Auto Scaling Group: $ASG_NAME"
echo "- Scale-Out Policy: $SCALE_OUT_POLICY_ARN"
echo "- Scale-In Policy: $SCALE_IN_POLICY_ARN"
echo "- Scale-Out Alarm: cpu-scaleout-alarm"
echo "- Scale-In Alarm: cpu-scalein-alarm"
