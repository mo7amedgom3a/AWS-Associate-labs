variable "vpc_cidr" {
	description = "CIDR block for the VPC"
	type        = string
	default     = "10.0.0.0/16"
}

variable "public_subnets" {
	description = "List of public subnet CIDR blocks"
	type        = list(string)
	default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
	description = "List of availability zones to use"
	type        = list(string)
	default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "instance_type" {
	description = "EC2 instance type"
	type        = string
	default     = "t3.micro"
}

variable "ami_id" {
	description = "AMI ID for EC2 instances"
	type        = string
	default     = "ami-00ca32bbc84273381" # Amazon Linux 2 (update as needed)
}

variable "key_name" {
	description = "Key pair name for SSH access"
	type        = string
	default     = "aws_keys"
}

variable "desired_capacity" {
	description = "Desired number of EC2 instances in ASG"
	type        = number
	default     = 2
}

variable "min_size" {
	description = "Minimum number of EC2 instances in ASG"
	type        = number
	default     = 2
}

variable "max_size" {
	description = "Maximum number of EC2 instances in ASG"
	type        = number
	default     = 4
}
