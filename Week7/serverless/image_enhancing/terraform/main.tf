terraform {
	required_version = ">= 1.0.0"
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = ">= 5.0"
		}
	}
}

provider "aws" {
	region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------
# S3 Bucket (raw + enhanced)
# -----------------
resource "aws_s3_bucket" "images" {
	bucket        = var.raw_bucket_name
	force_destroy = var.force_destroy_bucket
}

resource "aws_s3_bucket_public_access_block" "images" {
	bucket                  = aws_s3_bucket.images.id
	block_public_acls       = true
	block_public_policy     = true
	ignore_public_acls      = true
	restrict_public_buckets = true
}

# -----------------
# DynamoDB Table
# -----------------
resource "aws_dynamodb_table" "image_metadata" {
	name         = var.table_name
	billing_mode = "PAY_PER_REQUEST"
	hash_key     = "ImageId"

	attribute {
		name = "ImageId"
		type = "S"
	}
}

# -----------------
# SNS Topic (+ optional email subscription)
# -----------------
resource "aws_sns_topic" "notifications" {
	name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email" {
	count     = var.email_subscription != "" ? 1 : 0
	topic_arn = aws_sns_topic.notifications.arn
	protocol  = "email"
	endpoint  = var.email_subscription
}

# -----------------
# IAM Role and Policy for Lambda
# -----------------
data "aws_iam_policy_document" "assume_role" {
	statement {
		effect  = "Allow"
		principals {
			type        = "Service"
			identifiers = ["lambda.amazonaws.com"]
		}
		actions = ["sts:AssumeRole"]
	}
}

resource "aws_iam_role" "lambda" {
	name               = "${var.project_name}-lambda-role"
	assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "lambda_policy" {
	statement {
		sid     = "AllowLogs"
		effect  = "Allow"
		actions = [
			"logs:CreateLogGroup",
			"logs:CreateLogStream",
			"logs:PutLogEvents",
		]
		resources = ["arn:aws:logs:*:*:*"]
	}

	statement {
		sid     = "AllowS3"
		effect  = "Allow"
		actions = [
			"s3:GetObject",
			"s3:PutObject",
			"s3:ListBucket",
		]
		resources = [
			aws_s3_bucket.images.arn,
			"${aws_s3_bucket.images.arn}/*",
		]
	}

	statement {
		sid     = "AllowDynamoDB"
		effect  = "Allow"
		actions = [
			"dynamodb:PutItem",
			"dynamodb:GetItem",
		]
		resources = [aws_dynamodb_table.image_metadata.arn]
	}

	statement {
		sid     = "AllowSNS"
		effect  = "Allow"
		actions = [
			"sns:Publish",
		]
		resources = [aws_sns_topic.notifications.arn]
	}
}

resource "aws_iam_role_policy" "lambda_inline" {
	name   = "${var.project_name}-lambda-inline"
	role   = aws_iam_role.lambda.id
	policy = data.aws_iam_policy_document.lambda_policy.json
}

# -----------------
# ECR Repo and Docker Image build/push
# -----------------
resource "aws_ecr_repository" "lambda" {
	name                 = "${var.project_name}-lambda"
	image_tag_mutability = "MUTABLE"
	image_scanning_configuration {
		scan_on_push = true
	}
}

# -----------------
# Lambda Function (container image)
# -----------------
resource "aws_lambda_function" "image_enhancer" {
	function_name = "${var.project_name}-image-enhancer"
	package_type  = "Image"
	image_uri     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.lambda.name}:latest"
	role          = aws_iam_role.lambda.arn
	timeout       = var.lambda_timeout
	memory_size   = var.lambda_memory
	architectures = ["x86_64"]

	environment {
		variables = {
			TABLE_NAME         = aws_dynamodb_table.image_metadata.name
			SNS_TOPIC_ARN      = aws_sns_topic.notifications.arn
			TARGET_BUCKET_NAME = aws_s3_bucket.images.bucket
			ENHANCED_PREFIX    = var.enhanced_prefix
		}
	}


	depends_on = [aws_ecr_repository.lambda]
}

# Allow S3 to invoke the Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
	statement_id  = "AllowExecutionFromS3"
	action        = "lambda:InvokeFunction"
	function_name = aws_lambda_function.image_enhancer.function_name
	principal     = "s3.amazonaws.com"
	source_arn    = aws_s3_bucket.images.arn
}

# S3 -> Lambda notifications on object created
resource "aws_s3_bucket_notification" "images" {
	bucket = aws_s3_bucket.images.id

	lambda_function {
		lambda_function_arn = aws_lambda_function.image_enhancer.arn
		events              = ["s3:ObjectCreated:*"]
	}

	depends_on = [aws_lambda_permission.allow_s3_invoke]
}


