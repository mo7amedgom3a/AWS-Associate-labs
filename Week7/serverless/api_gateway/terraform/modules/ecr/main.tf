resource "aws_ecr_repository" "products" {
  name                 = "${var.project_name}-${var.environment}-products" # serverless-ecommerce-dev-products
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name        = "${var.project_name}-products-ecr"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "orders" {
  name                 = "${var.project_name}-${var.environment}-orders" # serverless-ecommerce-dev-orders
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name        = "${var.project_name}-orders-ecr"
    Environment = var.environment
  }
}
