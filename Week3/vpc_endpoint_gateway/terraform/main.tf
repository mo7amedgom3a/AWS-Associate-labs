provider "aws" {
	region = var.region
}

resource "aws_vpc" "main" {
	cidr_block           = var.vpc_cidr
	enable_dns_support   = true
	enable_dns_hostnames = true
	tags = {
		Name = "Gateway VPC"
	}
}

resource "aws_subnet" "private" {
	vpc_id                  = aws_vpc.main.id
	cidr_block              = var.private_subnet_cidr
	map_public_ip_on_launch = false
	availability_zone       = var.az
	tags = {
		Name = "Private Subnet"
	}
}

resource "aws_route_table" "private" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "Private Route Table"
	}
}

resource "aws_route_table_association" "private_assoc" {
	subnet_id      = aws_subnet.private.id
	route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
	vpc_id            = aws_vpc.main.id
	service_name      = "com.amazonaws.${var.region}.s3"
	route_table_ids   = [aws_route_table.private.id]
	vpc_endpoint_type = "Gateway"
	tags = {
		Name = "S3 Gateway Endpoint"
	}
}
