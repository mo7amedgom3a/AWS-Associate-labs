output "db_host" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.products.address
}

output "db_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.products.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.products.db_name
}

output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.products.endpoint
}
