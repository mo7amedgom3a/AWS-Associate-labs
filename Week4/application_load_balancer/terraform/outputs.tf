output "alb_dns_name" {
	description = "DNS name of the Application Load Balancer"
	value       = aws_lb.main.dns_name
}

output "vpc_id" {
	description = "ID of the VPC"
	value       = aws_vpc.main.id
}

output "autoscaling_group_name" {
	description = "Name of the Auto Scaling Group"
	value       = aws_autoscaling_group.main.name
}
