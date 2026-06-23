output "pcloud_account_name" {
  description = "Name of the vaulted Oracle account in Privilege Cloud"
  value       = idsec_pcloud_account.oracle_db.name
}

output "pcloud_account_id" {
  description = "ID of the vaulted Oracle account in Privilege Cloud"
  value       = idsec_pcloud_account.oracle_db.id
}

output "cyberark_safe_name" {
  description = "Privilege Cloud safe holding the Oracle credentials"
  value       = var.cyberark_safe_name
}

output "cyberark_platform_id" {
  description = "Platform used for the Oracle account"
  value       = var.cyberark_platform_id
}

output "sia_strong_account_id" {
  description = "ID of the SIA strong account linked to the vaulted Oracle credential"
  value       = idsec_sia_db_strong_accounts.oracle_db.id
}

output "sia_workspace_id" {
  description = "ID of the SIA DB workspace for the Oracle instance"
  value       = idsec_sia_workspaces_db.oracle_db.id
}

output "sia_workspace_name" {
  description = "Name of the SIA DB workspace for the Oracle instance"
  value       = idsec_sia_workspaces_db.oracle_db.name
}

output "policy_name" {
  description = "Name of the DB access policy"
  value       = var.idsec_policy_name
}

output "db_instance_id" {
  description = "RDS instance ID (from infrastructure state)"
  value       = local.db_instance_id
}

output "db_hostname" {
  description = "Oracle DB hostname (from infrastructure state)"
  value       = local.db_hostname
}

