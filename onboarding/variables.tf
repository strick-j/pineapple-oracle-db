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

variable "conjur_cyberark_client_id_path" {
  description = "Conjur variable path for the CyberArk service account client ID"
  type        = string
}

variable "conjur_cyberark_client_secret_path" {
  description = "Conjur variable path for the CyberArk service account client secret"
  type        = string
}

# ---------------------------------------------------------------------------
# CyberArk Privilege Cloud provider credentials
# Set via TF_VAR_cyberark_client_id / TF_VAR_cyberark_client_secret in CI/CD.
# These values are fetched from Conjur using IAM auth before terraform apply.
# ---------------------------------------------------------------------------

variable "cyberark_identity_url" {
  description = "CyberArk Identity tenant URL (e.g. https://example.id.cyberark.cloud)"
  type        = string
}

variable "cyberark_pas_url" {
  description = "CyberArk Privilege Cloud base URL (e.g. https://example.privilegecloud.cyberark.cloud)"
  type        = string
}

variable "cyberark_client_id" {
  description = "CyberArk service account client ID (sourced from Conjur via TF_VAR_)"
  type        = string
  sensitive   = true
}

variable "cyberark_client_secret" {
  description = "CyberArk service account client secret (sourced from Conjur via TF_VAR_)"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# CyberArk safe
# ---------------------------------------------------------------------------

variable "cyberark_safe_name" {
  description = "Name of the CyberArk safe that will hold Oracle DB credentials"
  type        = string
}

variable "create_cyberark_safe" {
  description = "Create the CyberArk safe (set false if the safe already exists)"
  type        = bool
  default     = true
}

variable "cyberark_safe_owner" {
  description = "CyberArk user or group that owns the safe"
  type        = string
}

variable "cyberark_safe_owner_type" {
  description = "Type of safe owner: user, group, or role"
  type        = string
  default     = "user"
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
  description = "Name of the CyberArk Central Policy Manager (CPM) responsible for rotation"
  type        = string
  default     = "PasswordManager"
}

# ---------------------------------------------------------------------------
# CyberArk account / UAP
# ---------------------------------------------------------------------------

variable "cyberark_platform_id" {
  description = "CyberArk platform ID for Oracle Database accounts (as configured in your vault)"
  type        = string
  default     = "Oracle"
}

variable "cyberark_access_members" {
  description = <<-EOT
    Map of CyberArk safe members to create for the access policy.
    Each key is the member name; value specifies the member type and permission level.
    permission_level accepted values: read, approver, manager, full
  EOT
  type = map(object({
    type             = string
    permission_level = string
  }))
  default = {}
}
