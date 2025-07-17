output "user_1_arn" {
  description = "ARN of user-1"
  value       = aws_iam_user.user_1.arn
}

output "user_2_arn" {
  description = "ARN of user-2"
  value       = aws_iam_user.user_2.arn
}

output "user_3_arn" {
  description = "ARN of user-3"
  value       = aws_iam_user.user_3.arn
}

output "ec2_admin_group" {
  description = "Name and ARN of EC2-Admin group"
  value = {
    name = aws_iam_group.ec2_admin.name
    arn  = aws_iam_group.ec2_admin.arn
  }
}

output "ec2_support_group" {
  description = "Name and ARN of EC2-Support group"
  value = {
    name = aws_iam_group.ec2_support.name
    arn  = aws_iam_group.ec2_support.arn
  }
}

output "s3_support_group" {
  description = "Name and ARN of S3-Support group"
  value = {
    name = aws_iam_group.s3_support.name
    arn  = aws_iam_group.s3_support.arn
  }
}
