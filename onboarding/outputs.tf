output "cyberark_account_name" {
  description = "Name of the vaulted Oracle account in CyberArk"
  value       = cyberark_account.oracle_db.name
}

output "cyberark_safe_name" {
  description = "CyberArk safe holding the Oracle credentials"
  value       = var.cyberark_safe_name
}

output "cyberark_platform_id" {
  description = "CyberArk platform used for the Oracle account"
  value       = var.cyberark_platform_id
}

output "db_instance_id" {
  description = "RDS instance ID (from infrastructure state)"
  value       = local.db_instance_id
}

output "db_hostname" {
  description = "Oracle DB hostname (from infrastructure state)"
  value       = local.db_hostname
}
