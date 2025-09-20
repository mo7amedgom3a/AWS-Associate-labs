variable "region" {
	type        = string
	description = "AWS region to deploy into"
	default     = "us-east-1"
}

variable "project_name" {
	type        = string
	description = "Project/name prefix for resources"
	default     = "image-enhancing"
}

variable "raw_bucket_name" {
	type        = string
	description = "S3 bucket name for raw and enhanced images"
	default     = "image-enhancing-raw-images-20-9-2025"
}

variable "enhanced_prefix" {
	type        = string
	description = "Prefix in the bucket to store enhanced images"
	default     = "enhanced/"
}

variable "table_name" {
	type        = string
	description = "DynamoDB table name for image metadata"
	default     = "ImageMetadata"
}

variable "sns_topic_name" {
	type        = string
	description = "SNS topic name for notifications"
	default     = "ImageNotifications"
}

variable "email_subscription" {
	type        = string
	description = "Optional email for SNS subscription"
	default     = "mo7amed.gom3a.7moda@gmail.com"
}

variable "force_destroy_bucket" {
	type        = bool
	description = "If true, allow force destroy of S3 bucket"
	default     = true
}

variable "lambda_timeout" {
	type        = number
	description = "Lambda timeout in seconds"
	default     = 60
}

variable "lambda_memory" {
	type        = number
	description = "Lambda memory in MB"
	default     = 1024
}


