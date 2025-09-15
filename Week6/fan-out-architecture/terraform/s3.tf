# S3 bucket for image uploads
resource "aws_s3_bucket" "image_upload" {
    bucket = "fanout-image-upload-bucket-${random_id.suffix.hex}"
    force_destroy = true
}

resource "random_id" "suffix" {
    byte_length = 4
}
