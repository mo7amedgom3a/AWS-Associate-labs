variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "serverless-ecommerce"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Username for RDS database"
  type        = string
  default = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Password for RDS database"
  type        = string
  default = "MySecurePassword123!"
  sensitive   = true
}
variable "ec2_ami" {
  description = "AMI for the EC2 instance"
  type        = string
  default = "ami-00ca32bbc84273381"
}

variable "key_name" {
  description = "Key name for the EC2 instance"
  type        = string
  default = "aws_keys"
}


variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "products"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "initialize_db" {
  description = "Whether to initialize the database with tables"
  type        = bool
  default     = false
}
