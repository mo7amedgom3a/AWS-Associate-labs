variable "aws_region" {
	description = "The AWS region to deploy resources in."
	type        = string
	default     = "us-east-1" # Default to us-east-1, change as needed
}

variable "notification_email" {
	description = "Email address to receive SNS notifications."
	type        = string
	default     = "mo7amed.gom3a.7moda@gmail.com"
}
