resource "aws_dynamodb_table" "orders" {
  name           = "${var.project_name}-${var.environment}-orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "order_id"
  range_key      = "customer_id"
  
  attribute {
    name = "order_id"
    type = "S"
  }
  
  attribute {
    name = "customer_id"
    type = "S"
  }
  
  tags = {
    Name        = "${var.project_name}-orders-table"
    Environment = var.environment
  }
}
