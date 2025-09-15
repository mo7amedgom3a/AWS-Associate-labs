# SQS queue for image processing
resource "aws_sqs_queue" "image_processing" {
	name = "image-processing-queue"
    
}
