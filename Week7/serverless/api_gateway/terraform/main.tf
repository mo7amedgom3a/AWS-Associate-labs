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
}

# DynamoDB table for Orders
module "dynamodb" {
  source = "./modules/dynamodb"
}

# VPC for networking
module "vpc" {
  source = "./modules/vpc"
}
