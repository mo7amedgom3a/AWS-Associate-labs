# SNS topic for image upload notifications
resource "aws_sns_topic" "image_upload" {
	name = "image-upload-notifications" 
}

# SNS email subscription (replace with your email)
resource "aws_sns_topic_subscription" "email" {
	topic_arn = aws_sns_topic.image_upload.arn
	protocol  = "email"
	endpoint  = var.notification_email
}

# SNS SQS subscription (SQS queue defined in sqs.tf)

resource "aws_sns_topic_subscription" "sqs" {
	topic_arn = aws_sns_topic.image_upload.arn
	protocol  = "sqs"
	endpoint  = aws_sqs_queue.image_processing.arn
}

# SNS topic policy to allow S3 to publish
resource "aws_sns_topic_policy" "s3_publish_policy" {
	arn = aws_sns_topic.image_upload.arn
	policy = jsonencode({
		Version = "2012-10-17"
		Statement = [{
			Effect    = "Allow"
			Principal = { Service = "s3.amazonaws.com" }
			Action    = "sns:Publish"
			Resource  = aws_sns_topic.image_upload.arn
			Condition = {
				StringEquals = {
					"aws:SourceArn" = aws_s3_bucket.image_upload.arn
				}
			}
		}]
	})
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "image_upload_notification" {
	bucket = aws_s3_bucket.image_upload.id

	topic {
		topic_arn = aws_sns_topic.image_upload.arn
		events    = ["s3:ObjectCreated:Put"]
	}

	depends_on = [aws_sns_topic_policy.s3_publish_policy]
}
