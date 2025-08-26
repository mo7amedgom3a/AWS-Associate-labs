variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-00ca32bbc84273381" // Amazon Linux 2023 AMI (us-east-1)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "aws private key name"
  default = "aws_keys"
  type        = string
}