output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "ecr_repo_url" {
  value = aws_ecr_repository.django_app.repository_url
}

output "ssh_command" {
  value = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.web.public_ip}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}
