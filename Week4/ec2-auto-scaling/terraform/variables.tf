variable "launch_template_name" {
	description = "Name prefix for the EC2 launch template"
	type        = string
	default     = "my-templet-web-server"
}

variable "ami_id" {
	description = "AMI ID for EC2 instances"
	type        = string
	default     = "ami-00ca32bbc84273381"
}

variable "instance_type" {
	description = "EC2 instance type"
	type        = string
	default     = "t2.micro"
}

variable "key_name" {
	description = "Key pair name for EC2 instances"
	type        = string
	default     = "aws_keys"
}

variable "security_group_id" {
	description = "Security group ID for EC2 instances"
	type        = string
	default     = "ssh-security-group"
}

variable "subnet_id" {
	description = "Subnet ID for EC2 instances"
	type        = string
	default     = "subnet-0b1cd5c1da71a79f4"
}

variable "asg_name" {
	description = "Name of the Auto Scaling Group"
	type        = string
	default     = "my-asg"
}

variable "min_size" {
	description = "Minimum number of instances in ASG"
	type        = number
	default     = 1
}

variable "max_size" {
	description = "Maximum number of instances in ASG"
	type        = number
	default     = 3
}

variable "desired_capacity" {
	description = "Desired number of instances in ASG"
	type        = number
	default     = 1
}

variable "cpu_threshold" {
	description = "CPU utilization threshold for scaling"
	type        = number
	default     = 50
}
