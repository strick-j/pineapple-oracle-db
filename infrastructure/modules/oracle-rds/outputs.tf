output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "RDS connection endpoint in host:port format"
  value       = aws_db_instance.this.endpoint
}

output "hostname" {
  description = "RDS instance hostname (without port)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Oracle listener port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Oracle SID"
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the Oracle DB security group"
  value       = aws_security_group.db.id
}
