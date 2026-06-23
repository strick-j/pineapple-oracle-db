# ---------------------------------------------------------------------------
# Read Oracle DB details from the infrastructure Terraform state.
# ---------------------------------------------------------------------------

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.state_key_prefix}/infrastructure/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  db_hostname    = data.terraform_remote_state.infrastructure.outputs.db_hostname
  db_port        = data.terraform_remote_state.infrastructure.outputs.db_port
  db_name        = data.terraform_remote_state.infrastructure.outputs.db_name
  db_username    = data.terraform_remote_state.infrastructure.outputs.db_username
  db_password    = data.terraform_remote_state.infrastructure.outputs.db_password
  db_instance_id = data.terraform_remote_state.infrastructure.outputs.db_instance_id
}

# ---------------------------------------------------------------------------
# Verify Conjur credential paths are reachable.
# (Values are also used for safe member confirmation — see providers.tf note
#  for why they cannot configure the cyberark provider directly.)
# ---------------------------------------------------------------------------

locals {
  # Explicit local references surface Conjur connectivity failures early,
  # before any CyberArk resources are created.
  conjur_client_id     = data.conjur_secret.cyberark_client_id.value
  conjur_client_secret = data.conjur_secret.cyberark_client_secret.value
}

# ---------------------------------------------------------------------------
# Step 1 — Create the CyberArk safe (UAP: onboard target safe)
# Set create_cyberark_safe = false if the safe already exists.
# ---------------------------------------------------------------------------

resource "cyberark_safe" "oracle_db" {
  count = var.create_cyberark_safe ? 1 : 0

  safe_name          = var.cyberark_safe_name
  description        = "Oracle DB credentials — ${local.db_instance_id} — managed by Terraform"
  member             = var.cyberark_safe_owner
  member_type        = var.cyberark_safe_owner_type
  permission_level   = "full"
  retention          = var.cyberark_safe_retention_days
  retention_versions = var.cyberark_safe_retention_versions
  purge              = false
  cpm_name           = var.cyberark_cpm_name
  safe_folder        = "\\Root\\"
}

# ---------------------------------------------------------------------------
# Step 2 — Vault Oracle credentials (UAP: Create DB account + Assign Strong Account)
#
# Using the Oracle platform assigns this as a database-type managed account.
# sm_manage = true enrolls the account for CPM rotation (strong account).
# platform_account_properties keys depend on the Oracle platform definition
# in your CyberArk vault — adjust Port / Database as needed.
# ---------------------------------------------------------------------------

resource "cyberark_account" "oracle_db" {
  name        = "oracle-${local.db_instance_id}"
  address     = local.db_hostname
  username    = local.db_username
  platform_id = var.cyberark_platform_id
  safe_name   = var.cyberark_safe_name

  secret      = local.db_password
  secret_type = "password"

  # Strong account: enables CPM-managed rotation
  sm_manage                            = true
  sm_manage_reason                     = "Managed by Terraform — pineapple-oracle-db"
  sm_automatic_reconcile_when_mismatch = true

  # Oracle-specific connection properties (adjust field names to match your platform)
  platform_account_properties = {
    Port     = tostring(local.db_port)
    Database = local.db_name
  }

  depends_on = [cyberark_safe.oracle_db]

  lifecycle {
    # CyberArk CPM owns password rotation; prevent Terraform from reverting it.
    ignore_changes = [secret]
  }
}

# ---------------------------------------------------------------------------
# Step 3 — Create access policy (UAP: Policy for access)
#
# Populate cyberark_access_members in terraform.tfvars to grant users/groups
# access to the vaulted Oracle credentials.
#
# Example:
#   cyberark_access_members = {
#     "app-team@example.com" = { type = "user",  permission_level = "use"  }
#     "dba-group"            = { type = "group", permission_level = "read" }
#   }
# ---------------------------------------------------------------------------

resource "cyberark_safe_member" "oracle_access" {
  for_each = var.cyberark_access_members

  safe_name        = var.cyberark_safe_name
  member_name      = each.key
  member_type      = each.value.type
  permission_level = each.value.permission_level

  depends_on = [cyberark_safe.oracle_db]
}
