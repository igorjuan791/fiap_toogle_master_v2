output "endpoints" {
  description = "Mapa identifier => endpoint (host:port)"
  value       = { for k, v in aws_db_instance.this : k => v.endpoint }
}

output "addresses" {
  description = "Mapa identifier => address (apenas host)"
  value       = { for k, v in aws_db_instance.this : k => v.address }
}
