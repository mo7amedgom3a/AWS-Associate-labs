variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "django-web-app"
}

variable "environment" {
  default = "development"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami_id" {
  default = "ami-0ff8a91507f77f867" # update as needed
}

variable "instance_name" {
  default = "django-web-server"
}

variable "key_name" {
  default = "aws_keys"
}

variable "private_key_path" {
  description = "Path to your private SSH key file"
  default     = "~/aws_keys.pem"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "ecr_repo_name" {
  default = "django-web-app"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project     = "django-web-app"
    Environment = "development"
    CreatedBy   = "terraform"
  }
}
