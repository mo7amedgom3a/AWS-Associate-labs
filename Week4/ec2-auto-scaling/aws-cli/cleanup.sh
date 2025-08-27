#!/bin/bash
# ================================
# Cleanup EC2 Auto Scaling + CloudWatch Resources
# ================================


# ---- Load variables from asg-resources.txt ----
RESOURCE_FILE="asg-resources.txt"
if [ ! -f "$RESOURCE_FILE" ]; then
    echo "ERROR: Resource file $RESOURCE_FILE not found."
    exit 1
fi

# shellcheck disable=SC1090
source "$RESOURCE_FILE"

# Use variables from resource file
ASG_NAME="${ASG_NAME}"
LT_NAME="${LAUNCH_TEMPLATE_NAME}"
REGION="${REGION}"
SCALE_OUT_POLICY="cpu-scaleout-policy"
SCALE_IN_POLICY="cpu-scalein-policy"
SCALEOUT_ALARM="${SCALEOUT_ALARM_NAME}"
SCALEIN_ALARM="${SCALEIN_ALARM_NAME}"

# Delete CloudWatch Alarms
aws cloudwatch delete-alarms --alarm-names "$SCALEOUT_ALARM" "$SCALEIN_ALARM" --region $REGION

# Delete Scaling Policies
aws autoscaling delete-policy --auto-scaling-group-name $ASG_NAME --policy-name $SCALE_OUT_POLICY --region $REGION
aws autoscaling delete-policy --auto-scaling-group-name $ASG_NAME --policy-name $SCALE_IN_POLICY --region $REGION

# Delete Auto Scaling Group (force delete, set min/max/desired to 0 first)
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 0 --max-size 0 --desired-capacity 0 --region $REGION
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME --force-delete --region $REGION

# Delete Launch Template
LT_ID=$(aws ec2 describe-launch-templates --launch-template-names $LT_NAME --query 'LaunchTemplates[0].LaunchTemplateId' --output text --region $REGION)
if [ "$LT_ID" != "None" ] && [ -n "$LT_ID" ]; then
    aws ec2 delete-launch-template --launch-template-id $LT_ID --region $REGION
    echo "✓ Launch Template deleted: $LT_ID"
else
    echo "Launch Template not found: $LT_NAME"
fi

echo "Cleanup complete."
