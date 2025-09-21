output "products_repository_url" {
  description = "URL of the ECR repository for the Products service"
  value       = aws_ecr_repository.products.repository_url
}

output "orders_repository_url" {
  description = "URL of the ECR repository for the Orders service"
  value       = aws_ecr_repository.orders.repository_url
}
