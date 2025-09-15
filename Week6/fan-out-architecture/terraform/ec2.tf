# Security group for EC2 instances (allow SSH, HTTP, custom as needed)
resource "aws_security_group" "upload_service" {
	name        = "upload-service-sg"
	description = "Allow SSH and HTTP for upload service"
	vpc_id      = data.aws_vpc.default.id

	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
    ingress {
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "processing_service" {
	name        = "processing-service-sg"
	description = "Allow SSH for processing service"
	vpc_id      = data.aws_vpc.default.id

	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

# EC2 Instance 1: Upload Service
resource "aws_instance" "upload_service" {
	ami                         = data.aws_ami.amazon_linux.id
	instance_type               = "t3.micro"
	subnet_id                   = data.aws_subnet.default.id
	key_name                    = "aws_keys"
	vpc_security_group_ids      = [aws_security_group.upload_service.id]
	iam_instance_profile        = aws_iam_instance_profile.upload_service.name
	associate_public_ip_address = true
	tags = {
		Name = "UploadServiceEC2"
	}
}

# EC2 Instance 2: Processing Service
resource "aws_instance" "processing_service" {
	ami                         = data.aws_ami.amazon_linux.id
	instance_type               = "t3.micro"
	subnet_id                   = data.aws_subnet.default.id
	key_name                    = "aws_keys"
	vpc_security_group_ids      = [aws_security_group.processing_service.id]
	iam_instance_profile        = aws_iam_instance_profile.processing_service.name
	associate_public_ip_address = true
	tags = {
		Name = "ProcessingServiceEC2"
	}
}
