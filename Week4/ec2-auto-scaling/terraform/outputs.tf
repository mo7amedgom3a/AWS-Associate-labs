output "launch_template_id" {
	description = "ID of the EC2 launch template"
	value       = aws_launch_template.web_server.id
}

output "autoscaling_group_name" {
	description = "Name of the Auto Scaling Group"
	value       = aws_autoscaling_group.web_asg.name
}

output "scale_out_policy_arn" {
	description = "ARN of the scale-out policy"
	value       = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
	description = "ARN of the scale-in policy"
	value       = aws_autoscaling_policy.scale_in.arn
}

output "scale_out_alarm_name" {
	description = "Name of the scale-out CloudWatch alarm"
	value       = aws_cloudwatch_metric_alarm.scale_out_alarm.alarm_name
}

output "scale_in_alarm_name" {
	description = "Name of the scale-in CloudWatch alarm"
	value       = aws_cloudwatch_metric_alarm.scale_in_alarm.alarm_name
}
