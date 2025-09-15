output "s3_bucket_name" {
	value = aws_s3_bucket.image_upload.bucket
	description = "S3 bucket name for image uploads."
}

output "sns_topic_arn" {
	value = aws_sns_topic.image_upload.arn
	description = "SNS topic ARN for image upload notifications."
}

output "sqs_queue_url" {
	value = aws_sqs_queue.image_processing.url
	description = "SQS queue URL for image processing."
}

output "sqs_queue_arn" {
	value = aws_sqs_queue.image_processing.arn
	description = "SQS queue ARN for image processing."
}

output "dynamodb_table_name" {
	value = aws_dynamodb_table.image_metadata.name
	description = "DynamoDB table name for image metadata."
}

output "upload_service_public_ip" {
	value = aws_instance.upload_service.public_ip
	description = "Public IPv4 address of the upload service EC2 instance."
}

output "processing_service_public_ip" {
	value = aws_instance.processing_service.public_ip
	description = "Public IPv4 address of the processing service EC2 instance."
}
