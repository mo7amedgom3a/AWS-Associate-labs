output "website_url" {
  description = "URL of the static website"
  value       = module.website.website_url
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_gateway_url
}

output "products_api_url" {
  description = "URL of the Products API"
  value       = "${module.api_gateway.api_gateway_url}/products"
}

output "orders_api_url" {
  description = "URL of the Orders API"
  value       = "${module.api_gateway.api_gateway_url}/orders"
}

output "products_ecr_repository_url" {
  description = "URL of the Products ECR repository"
  value       = module.ecr.products_repository_url
}

output "orders_ecr_repository_url" {
  description = "URL of the Orders ECR repository"
  value       = module.ecr.orders_repository_url
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.db_host
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.orders_table_name
}
