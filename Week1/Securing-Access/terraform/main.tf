# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create IAM Users
resource "aws_iam_user" "user_1" {
  name = "user-1"
}

resource "aws_iam_user" "user_2" {
  name = "user-2"
}

resource "aws_iam_user" "user_3" {
  name = "user-3"
}

# Create IAM Groups
resource "aws_iam_group" "ec2_admin" {
  name = "EC2-Admin"
}

resource "aws_iam_group" "ec2_support" {
  name = "EC2-Support"
}

resource "aws_iam_group" "s3_support" {
  name = "S3-Support"
}

# Create inline policy for EC2-Admin group
resource "aws_iam_group_policy" "ec2_admin_policy" {
  name  = "EC2AdminInlinePolicy"
  group = aws_iam_group.ec2_admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach managed policy for EC2 read-only access to EC2-Support group
resource "aws_iam_group_policy_attachment" "ec2_support_policy" {
  group      = aws_iam_group.ec2_support.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Attach managed policy for S3 read-only access to S3-Support group
resource "aws_iam_group_policy_attachment" "s3_support_policy" {
  group      = aws_iam_group.s3_support.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Add users to groups
resource "aws_iam_user_group_membership" "user_1_membership" {
  user = aws_iam_user.user_1.name
  groups = [
    aws_iam_group.ec2_admin.name
  ]
}

resource "aws_iam_user_group_membership" "user_2_membership" {
  user = aws_iam_user.user_2.name
  groups = [
    aws_iam_group.ec2_support.name
  ]
}

resource "aws_iam_user_group_membership" "user_3_membership" {
  user = aws_iam_user.user_3.name
  groups = [
    aws_iam_group.s3_support.name
  ]
}
