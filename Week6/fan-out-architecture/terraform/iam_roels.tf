# IAM Role for EC2 Instance 1: Upload Service
resource "aws_iam_role" "upload_service" {
	name = "ImageUploadServiceRole"
	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement = [{
			Effect = "Allow"
			Principal = { Service = "ec2.amazonaws.com" }
			Action = "sts:AssumeRole"
		}]
	})
}

resource "aws_iam_role_policy" "upload_service_policy" {
	name = "S3UploadPolicy"
	role = aws_iam_role.upload_service.id
	policy = jsonencode({
		Version = "2012-10-17"
		Statement = [{
			Effect = "Allow"
			Action = [
				"s3:PutObject",
				"s3:PutObjectAcl"
			]
			Resource = "${aws_s3_bucket.image_upload.arn}/*"
		}]
	})
}

resource "aws_iam_instance_profile" "upload_service" {
	name = "ImageUploadServiceProfile"
	role = aws_iam_role.upload_service.name
}

# IAM Role for EC2 Instance 2: Processing Service
resource "aws_iam_role" "processing_service" {
	name = "ImageProcessingServiceRole"
	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement = [{
			Effect = "Allow"
			Principal = { Service = "ec2.amazonaws.com" }
			Action = "sts:AssumeRole"
		}]
	})
}

resource "aws_iam_role_policy" "processing_service_policy" {
	name = "SQSDynamoDBPolicy"
	role = aws_iam_role.processing_service.id
	policy = jsonencode({
		Version = "2012-10-17"
		Statement = [
			{
				Effect = "Allow"
				Action = [
					"sqs:ReceiveMessage",
					"sqs:DeleteMessage",
					"sqs:GetQueueAttributes"
				]
				Resource = aws_sqs_queue.image_processing.arn
			},
			{
				Effect = "Allow"
				Action = [
					"dynamodb:PutItem",
					"dynamodb:GetItem",
					"dynamodb:UpdateItem"
				]
				Resource = aws_dynamodb_table.image_metadata.arn
			}
		]
	})
}

resource "aws_iam_instance_profile" "processing_service" {
	name = "ImageProcessingServiceProfile"
	role = aws_iam_role.processing_service.name
}
