variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "create_password" {
  description = "Whether to create console passwords for the users"
  type        = bool
  default     = false
}

variable "password_reset_required" {
  description = "Whether the user should be forced to reset the password on first login"
  type        = bool
  default     = true
}
