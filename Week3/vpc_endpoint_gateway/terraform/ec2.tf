resource "aws_iam_role" "ec2_s3" {
	name = "ec2_s3_access_role"
	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement = [{
			Effect = "Allow"
			Principal = { Service = "ec2.amazonaws.com" }
			Action = "sts:AssumeRole"
		}]
	})
}

resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
	role       = aws_iam_role.ec2_s3.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
	name = "ec2_s3_profile"
	role = aws_iam_role.ec2_s3.name
}

resource "aws_security_group" "private_sg" {
	name        = "private_ec2_sg"
	description = "Allow SSH from anywhere (for demo, restrict in production)"
	vpc_id      = aws_vpc.main.id

	ingress {
		description      = "SSH"
		from_port        = 22
		to_port          = 22
		protocol         = "tcp"
		cidr_blocks      = ["0.0.0.0/0"]
	}

	egress {
		from_port        = 0
		to_port          = 0
		protocol         = "-1"
		cidr_blocks      = ["0.0.0.0/0"]
	}

	tags = {
		Name = "Private EC2 SG"
	}
}

resource "aws_instance" "private_ec2" {
	ami                         = var.ami_id
	instance_type               = var.instance_type
	subnet_id                   = aws_subnet.private.id
	associate_public_ip_address = false
	vpc_security_group_ids      = [aws_security_group.private_sg.id]
	key_name                    = var.key_name
	iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

	user_data = <<-EOF
		#!/bin/bash
		yum update -y
		yum install -y aws-cli
		echo "Test S3 access:" > /home/ec2-user/s3_test.txt
		aws s3 ls > /home/ec2-user/s3_test.txt
	EOF

	tags = {
		Name = "Private EC2 Instance"
	}
}
