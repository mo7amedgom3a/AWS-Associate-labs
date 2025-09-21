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

variable "products_lambda_invoke_arn" {
  description = "ARN of the Products Lambda function for API Gateway integration"
  type        = string
}

variable "orders_lambda_invoke_arn" {
  description = "ARN of the Orders Lambda function for API Gateway integration"
  type        = string
}

variable "products_lambda_function_name" {
  description = "Name of the Products Lambda function"
  type        = string
  default     = "products-service"
}

variable "orders_lambda_function_name" {
  description = "Name of the Orders Lambda function"
  type        = string
  default     = "orders-service"
}
