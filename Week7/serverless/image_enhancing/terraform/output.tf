output "bucket_name" {
	value       = aws_s3_bucket.images.bucket
	description = "S3 bucket for raw and enhanced images"
}

output "dynamodb_table" {
	value       = aws_dynamodb_table.image_metadata.name
	description = "DynamoDB table name"
}

output "sns_topic_arn" {
	value       = aws_sns_topic.notifications.arn
	description = "SNS topic ARN"
}

output "lambda_function_name" {
	value       = aws_lambda_function.image_enhancer.function_name
	description = "Lambda function name"
}

output "lambda_image_uri" {
	value       = aws_lambda_function.image_enhancer.image_uri
	description = "Lambda container image URI"
}


