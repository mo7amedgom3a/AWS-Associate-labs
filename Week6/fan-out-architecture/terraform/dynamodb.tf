# DynamoDB table for image metadata
resource "aws_dynamodb_table" "image_metadata" {
	name         = "ImageMetadata"
	billing_mode   = "PAY_PER_REQUEST"
	hash_key     = "ImageId"

	attribute {
		name = "ImageId"
		type = "S"
	}
    tags = {
        Name = "ImageMetadataTable"
    }
}
