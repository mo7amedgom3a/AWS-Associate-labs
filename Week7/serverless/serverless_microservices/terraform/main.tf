provider "aws" {
  region = var.aws_region
}

# S3 bucket for static website hosting
module "website" {
  source = "./modules/s3"
}

# API Gateway setup
module "api_gateway" {
  source = "./modules/api_gateway"
  products_lambda_invoke_arn = module.products_lambda.lambda_invoke_arn
  orders_lambda_invoke_arn   = module.orders_lambda.lambda_invoke_arn
  products_lambda_function_name = module.products_lambda.lambda_function_name
  orders_lambda_function_name = module.orders_lambda.lambda_function_name
}

# ECR repositories for Docker images
module "ecr" {
  source = "./modules/ecr"
}

# Lambda function for Products service
module "products_lambda" {
  source         = "./modules/lambda"
  function_name  = "products-service"
  ecr_repository = module.ecr.products_repository_url
  image_uri      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/serverless-ecommerce-dev-products:latest"
  subnet_ids     = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.lambda_security_group_id]
  environment_variables = {
    DB_HOST     = module.rds.db_host
    DB_PORT     = module.rds.db_port
    DB_NAME     = module.rds.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
  }
}

# Lambda function for Orders service
module "orders_lambda" {
  source         = "./modules/lambda"
  function_name  = "orders-service"
  ecr_repository = module.ecr.orders_repository_url
  image_uri      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/serverless-ecommerce-dev-orders:latest"
  subnet_ids     = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.lambda_security_group_id]
  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.orders_table_name
  }
}

# RDS MySQL database for Products
module "rds" {
  source              = "./modules/rds"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  db_security_group_id = module.vpc.db_security_group_id
  db_username         = var.db_username
  db_password         = var.db_password
  initialize_db       = var.initialize_db
}
#EC2 instance for database management
resource "aws_instance" "db_manager" {
  ami                         = var.ec2_ami
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [module.vpc.db_security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-db-manager"
    Environment = var.environment
  }
  
}

# DynamoDB table for Orders
module "dynamodb" {
  source = "./modules/dynamodb"
}

# VPC for networking
module "vpc" {
  source = "./modules/vpc"
}
