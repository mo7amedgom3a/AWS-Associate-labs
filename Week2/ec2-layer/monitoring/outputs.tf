# Output the Prometheus + Grafana instance IP
output "prometheus_grafana_ip" {
  description = "Public IP of Prometheus + Grafana server"
  value       = aws_instance.prometheus_grafana.public_ip
}

# Output Node Exporter instance IPs
output "node_exporter_ips" {
  description = "Public IPs of Node Exporter servers"
  value       = [for instance in aws_instance.node_exporter : instance.public_ip]
}

