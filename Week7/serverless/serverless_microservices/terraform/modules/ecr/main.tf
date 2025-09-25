data "aws_ecr_repository" "products" {
  name = "${var.project_name}-${var.environment}-products" # serverless-ecommerce-dev-products
}

data "aws_ecr_repository" "orders" {
  name = "${var.project_name}-${var.environment}-orders" # serverless-ecommerce-dev-orders
}
