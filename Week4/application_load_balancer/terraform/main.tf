resource "aws_security_group" "ec2" {
	name        = "alb-lab-ec2-sg"
	description = "Allow HTTP from ALB"
	vpc_id      = aws_vpc.main.id

	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		security_groups = [aws_security_group.alb.id]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "alb" {
	name        = "alb-lab-alb-sg"
	description = "Allow HTTP from internet"
	vpc_id      = aws_vpc.main.id

	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

data "template_file" "user_data" {
	template = <<-EOF
		#!/bin/bash
		yum update -y
		yum install -y httpd
		systemctl enable httpd
		systemctl start httpd
		echo "<h1>Welcome to My Auto Scaling App</h1>" > /var/www/html/index.html
	EOF
}

resource "aws_launch_template" "main" {
	name_prefix   = "alb-lab-launch-template-"
	image_id      = var.ami_id
	instance_type = var.instance_type
	key_name      = var.key_name
	user_data     = base64encode(data.template_file.user_data.rendered)
	vpc_security_group_ids = [aws_security_group.ec2.id]
}

resource "aws_lb" "main" {
	name               = "alb-lab-alb"
	internal           = false
	load_balancer_type = "application"
	security_groups    = [aws_security_group.alb.id]
	subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_target_group" "main" {
	name     = "alb-lab-tg"
	port     = 80
	protocol = "HTTP"
	vpc_id   = aws_vpc.main.id
	health_check {
		path                = "/"
		protocol            = "HTTP"
		matcher             = "200"
		interval            = 30
		timeout             = 5
		healthy_threshold   = 2
		unhealthy_threshold = 2
	}
}

resource "aws_lb_listener" "main" {
	load_balancer_arn = aws_lb.main.arn
	port              = 80
	protocol          = "HTTP"
	default_action {
		type             = "forward"
		target_group_arn = aws_lb_target_group.main.arn
	}
}

resource "aws_autoscaling_group" "main" {
	name                      = "alb-lab-asg"
	min_size                  = var.min_size
	max_size                  = var.max_size
	desired_capacity          = var.desired_capacity
	vpc_zone_identifier       = [for subnet in aws_subnet.public : subnet.id]
	launch_template {
		id      = aws_launch_template.main.id
		version = "$Latest"
	}
	target_group_arns         = [aws_lb_target_group.main.arn]
	health_check_type         = "EC2"
	health_check_grace_period = 300
	tag {
		key                 = "Name"
		value               = "alb-lab-asg-instance"
		propagate_at_launch = true
	}
}
