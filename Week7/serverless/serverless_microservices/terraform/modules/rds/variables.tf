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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the RDS instance"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "db_username" {
  description = "Username for the RDS instance"
  type        = string
}
variable "db_password" {
  description = "Password for the RDS instance"
  type        = string
  default = "MySecurePassword123!"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "products"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "initialize_db" {
  description = "Whether to initialize the database with tables"
  type        = bool
  default     = false
}
