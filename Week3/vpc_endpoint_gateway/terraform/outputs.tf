output "private_ec2_id" {
	description = "ID of the EC2 instance in private subnet"
	value       = aws_instance.private_ec2.id
}

output "vpc_endpoint_id" {
	description = "ID of the S3 Gateway VPC Endpoint"
	value       = aws_vpc_endpoint.s3.id
}
