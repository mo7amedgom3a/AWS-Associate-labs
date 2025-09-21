output "orders_table_name" {
  description = "Name of the DynamoDB table for orders"
  value       = aws_dynamodb_table.orders.name
}

output "orders_table_arn" {
  description = "ARN of the DynamoDB table for orders"
  value       = aws_dynamodb_table.orders.arn
}
