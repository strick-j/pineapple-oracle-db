output "db_instance_id" {
  description = "RDS instance identifier"
  value       = module.oracle_rds.instance_id
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = module.oracle_rds.arn
}

output "db_endpoint" {
  description = "RDS connection endpoint in host:port format"
  value       = module.oracle_rds.endpoint
}

output "db_hostname" {
  description = "RDS instance hostname (without port)"
  value       = module.oracle_rds.hostname
}

output "db_port" {
  description = "Oracle listener port"
  value       = module.oracle_rds.port
}

output "db_name" {
  description = "Oracle SID / database name"
  value       = module.oracle_rds.db_name
}

output "db_username" {
  description = "Master username for the Oracle DB"
  value       = module.oracle_rds.username
  sensitive   = true
}

output "db_password" {
  description = "Master password for the Oracle DB (initial; CyberArk CPM will rotate)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_security_group_id" {
  description = "ID of the security group created for the Oracle DB"
  value       = module.oracle_rds.security_group_id
}
