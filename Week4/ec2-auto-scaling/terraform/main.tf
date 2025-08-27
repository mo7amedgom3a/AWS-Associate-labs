resource "aws_launch_template" "web_server" {
	name_prefix   = var.launch_template_name
	image_id      = var.ami_id
	instance_type = var.instance_type
	key_name      = var.key_name
	user_data     = filebase64("${path.module}/user_data.txt")
	vpc_security_group_ids = [var.security_group_id]
}

resource "aws_autoscaling_group" "web_asg" {
	name                      = var.asg_name
	min_size                  = var.min_size
	max_size                  = var.max_size
	desired_capacity          = var.desired_capacity
	vpc_zone_identifier       = [var.subnet_id]
	launch_template {
		id      = aws_launch_template.web_server.id
		version = "$Latest"
	}
	tag {
		key                 = "Name"
		value               = var.asg_name
		propagate_at_launch = true
	}
}

resource "aws_autoscaling_policy" "scale_out" {
	name                   = "cpu-scaleout-policy"
	autoscaling_group_name = aws_autoscaling_group.web_asg.name
	scaling_adjustment     = 1
	adjustment_type        = "ChangeInCapacity"
}

resource "aws_autoscaling_policy" "scale_in" {
	name                   = "cpu-scalein-policy"
	autoscaling_group_name = aws_autoscaling_group.web_asg.name
	scaling_adjustment     = -1
	adjustment_type        = "ChangeInCapacity"
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
	alarm_name                = "cpu-scaleout-alarm"
	comparison_operator       = "GreaterThanThreshold"
	evaluation_periods        = 2
	metric_name               = "CPUUtilization"
	namespace                 = "AWS/EC2"
	period                    = 300
	statistic                 = "Average"
	threshold                 = var.cpu_threshold
	alarm_actions             = [aws_autoscaling_policy.scale_out.arn]
	dimensions = {
		AutoScalingGroupName = aws_autoscaling_group.web_asg.name
	}
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
	alarm_name                = "cpu-scalein-alarm"
	comparison_operator       = "LessThanThreshold"
	evaluation_periods        = 2
	metric_name               = "CPUUtilization"
	namespace                 = "AWS/EC2"
	period                    = 300
	statistic                 = "Average"
	threshold                 = var.cpu_threshold
	alarm_actions             = [aws_autoscaling_policy.scale_in.arn]
	dimensions = {
		AutoScalingGroupName = aws_autoscaling_group.web_asg.name
	}
}
