# S3 bucket for image uploads
resource "aws_s3_bucket" "image_upload" {
    bucket = "fanout-image-upload-bucket-${random_id.suffix.hex}"
    force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "image_upload" {
  bucket = aws_s3_bucket.image_upload.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "image_upload" {
  bucket = aws_s3_bucket.image_upload.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "random_id" "suffix" {
    byte_length = 4
}
