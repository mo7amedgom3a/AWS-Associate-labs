
variable "s3_bucket_name" {
	description = "Name of the S3 bucket to create"
	default     = "my-bucket-1234566mohamed"
	type        = string
}
variable "region" {
	description = "AWS region"
	type        = string
	default     = "us-east-1"
}

variable "vpc_cidr" {
	description = "CIDR block for VPC"
	type        = string
	default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
	description = "CIDR block for private subnet"
	type        = string
	default     = "10.0.2.0/24"
}

variable "az" {
	description = "Availability zone for private subnet"
	type        = string
	default     = "us-east-1a"
}

variable "ami_id" {
	description = "AMI ID for EC2 instance"
	type        = string
	default     = "ami-00ca32bbc84273381"
}

variable "instance_type" {
	description = "EC2 instance type"
	type        = string
	default     = "t2.micro"
}

variable "key_name" {
	description = "Key pair name for SSH access"
    default = "aws_keys"
	type        = string
}




