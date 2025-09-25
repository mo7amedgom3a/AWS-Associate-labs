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

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "ecr_repository" {
  description = "ECR repository URL for the Lambda function"
  type        = string
}

variable "image_uri" {
  description = "Docker image URI for the Lambda function"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the Lambda function"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the Lambda function"
  type        = list(string)
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}
