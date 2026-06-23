# ---------------------------------------------------------------------------
# Connector Management — pool identifier
# ---------------------------------------------------------------------------

variable "connector_pool_id" {
  description = "ID of the existing connector pool to which the Oracle DB FQDN will be added"
  type        = string
}

# ---------------------------------------------------------------------------
# AWS & State
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region (must match the infrastructure configuration)"
  type        = string
  default     = "us-east-2"
}

variable "state_bucket" {
  description = "S3 bucket that holds the infrastructure Terraform state"
  type        = string
}

variable "state_key_prefix" {
  description = "Key prefix used in the infrastructure state bucket"
  type        = string
  default     = "pineapple-oracle-db"
}

variable "i_owner" {
  description = "Owner identifier (must match the infrastructure I_Owner tag)"
  type        = string
}

# ---------------------------------------------------------------------------
# Conjur — IAM host role authentication
# ---------------------------------------------------------------------------

variable "conjur_url" {
  description = "Conjur appliance HTTPS URL (e.g. https://conjur.example.com)"
  type        = string
}

variable "conjur_account" {
  description = "Conjur account name"
  type        = string
}

variable "conjur_authn_login" {
  description = "Conjur host identity for the IAM role (e.g. host/aws/sts/my-role)"
  type        = string
}

variable "conjur_idsec_username_path" {
  description = "Conjur variable path for the idsec provider username"
  type        = string
}

variable "conjur_idsec_secret_path" {
  description = "Conjur variable path for the idsec provider secret"
  type        = string
}

# ---------------------------------------------------------------------------
# idsec provider credentials
# Set via TF_VAR_idsec_username / TF_VAR_idsec_secret in CI/CD.
# These values are fetched from Conjur using IAM auth before terraform apply.
# ---------------------------------------------------------------------------

variable "idsec_username" {
  description = "idsec provider username (sourced from Conjur via TF_VAR_)"
  type        = string
  sensitive   = true
}

variable "idsec_secret" {
  description = "idsec provider secret (sourced from Conjur via TF_VAR_)"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Privilege Cloud — safe
# ---------------------------------------------------------------------------

variable "cyberark_safe_name" {
  description = "Name of the Privilege Cloud safe that will hold Oracle DB credentials"
  type        = string
}

variable "create_cyberark_safe" {
  description = "Create the Privilege Cloud safe (set false if the safe already exists)"
  type        = bool
  default     = true
}

variable "cyberark_safe_retention_days" {
  description = "Number of days to retain old credential versions in the safe"
  type        = number
  default     = 7
}

variable "cyberark_safe_retention_versions" {
  description = "Number of credential versions to retain in the safe"
  type        = number
  default     = 5
}

variable "cyberark_cpm_name" {
  description = "Name of the CPM user that will manage the safe"
  type        = string
  default     = "PasswordManager"
}

# ---------------------------------------------------------------------------
# Privilege Cloud — account / platform
# ---------------------------------------------------------------------------

variable "cyberark_platform_id" {
  description = "Privilege Cloud platform ID for Oracle Database accounts"
  type        = string
  default     = "Oracle"
}

# ---------------------------------------------------------------------------
# Privilege Cloud — safe members (access policy)
#
# Map key   = member name (user or group)
# member_type    accepted values : User | Group | Role
# permission_set accepted values : connect_only | read_only | approver |
#                                   accounts_manager | full | custom
# ---------------------------------------------------------------------------

variable "cyberark_access_members" {
  description = <<-EOT
    Map of Privilege Cloud safe members for the access policy.
    Each key is the member name; value specifies the member type and permission set.
  EOT
  type = map(object({
    member_type    = string
    permission_set = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# SIA — DB strong account
# ---------------------------------------------------------------------------

variable "idsec_strong_account_name_suffix" {
  description = "Suffix appended to the DB instance ID to form the strong account name"
  type        = string
  default     = "strong"
}

# ---------------------------------------------------------------------------
# SIA — DB workspace
# ---------------------------------------------------------------------------

variable "idsec_db_provider_engine" {
  description = "SIA provider engine for the Oracle DB workspace (e.g. oracle-sh-vm)"
  type        = string
  default     = "oracle-sh-vm"
}

variable "idsec_db_configured_auth_method" {
  description = "Configured authentication method type for the SIA DB workspace (e.g. local_db_auth)"
  type        = string
  default     = "local_db_auth"
}

# ---------------------------------------------------------------------------
# SIA — DB access policy
# ---------------------------------------------------------------------------

variable "idsec_policy_name" {
  description = "Name of the idsec DB access policy"
  type        = string
  default     = "oracle-db-access-policy"
}

variable "idsec_policy_timezone" {
  description = "Timezone for the DB access policy (IANA format, e.g. America/New_York)"
  type        = string
  default     = "UTC"
}

variable "idsec_policy_principals" {
  description = <<-EOT
    List of principals (users, groups, or roles) that the DB policy applies to.
    type accepted values: USER | GROUP | ROLE
    source_directory_id / source_directory_name are required unless type is ROLE.
  EOT
  type = list(object({
    id                    = string
    name                  = string
    type                  = string
    source_directory_id   = optional(string)
    source_directory_name = optional(string)
  }))
  default = []
}

variable "idsec_policy_oracle_dba_role" {
  description = "Grant DBA role to users connecting via the DB access policy"
  type        = bool
  default     = false
}

variable "idsec_policy_oracle_sysdba_role" {
  description = "Grant SYSDBA role to users connecting via the DB access policy"
  type        = bool
  default     = false
}

variable "idsec_policy_oracle_sysoper_role" {
  description = "Grant SYSOPER role to users connecting via the DB access policy"
  type        = bool
  default     = false
}

variable "idsec_policy_oracle_roles" {
  description = "List of Oracle roles assigned to users connecting via the DB access policy"
  type        = list(string)
  default     = ["CONNECT"]
}

variable "idsec_policy_max_session_duration" {
  description = "Maximum session duration in hours for the DB access policy"
  type        = number
  default     = 8
}

