resource "aws_s3_bucket" "demo" {
	bucket = var.s3_bucket_name
	acl    = "private"
	tags = {
		Name = "Demo S3 Bucket"
	}
}
