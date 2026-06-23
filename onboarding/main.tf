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
# Verify idsec credential paths in Conjur are reachable.
# (Values are also validated here before any Privilege Cloud resources are
#  created — see providers.tf note for why they cannot configure the idsec
#  provider directly.)
# ---------------------------------------------------------------------------

locals {
  conjur_idsec_username = data.conjur_secret.idsec_username.value
  conjur_idsec_secret   = data.conjur_secret.idsec_secret.value
}

# ---------------------------------------------------------------------------
# Convenience local: safe_id for use in safe members.
# When the safe is created here, use the resource output. Otherwise fall back
# to the safe name (valid for names without special characters).
# ---------------------------------------------------------------------------

locals {
  pcloud_safe_id = var.create_cyberark_safe ? idsec_pcloud_safe.oracle_db[0].safe_id : var.cyberark_safe_name
}

# ---------------------------------------------------------------------------
# Step 1 — Create the Privilege Cloud safe
# Set create_cyberark_safe = false if the safe already exists.
# ---------------------------------------------------------------------------

resource "idsec_pcloud_safe" "oracle_db" {
  count = var.create_cyberark_safe ? 1 : 0

  safe_name                    = var.cyberark_safe_name
  description                  = "Oracle DB credentials — ${local.db_instance_id} — managed by Terraform"
  managing_cpm                 = var.cyberark_cpm_name
  number_of_days_retention     = var.cyberark_safe_retention_days
  number_of_versions_retention = var.cyberark_safe_retention_versions
}

# ---------------------------------------------------------------------------
# Step 2 — Vault Oracle credentials into the safe (idsec Privilege Cloud account)
#
# automatic_management_enabled = true enrolls the account for CPM rotation.
# platform_account_properties keys are defined by the Oracle platform in your
# Privilege Cloud vault — adjust Port / Database names as needed.
# ---------------------------------------------------------------------------

resource "idsec_pcloud_account" "oracle_db" {
  safe_name   = var.cyberark_safe_name
  name        = "oracle-${local.db_instance_id}"
  platform_id = var.cyberark_platform_id
  address     = local.db_hostname
  username    = local.db_username
  secret      = local.db_password
  secret_type = "password"

  automatic_management_enabled = true

  platform_account_properties = {
    Port     = tostring(local.db_port)
    Database = local.db_name
  }

  depends_on = [idsec_pcloud_safe.oracle_db]

  lifecycle {
    # CPM owns rotation after initial creation; prevent Terraform from reverting.
    ignore_changes = [secret]
  }
}

# ---------------------------------------------------------------------------
# Step 3 — Grant safe membership (access policy for the vaulted credential)
#
# Populate cyberark_access_members in terraform.tfvars to grant users/groups
# access to retrieve the vaulted Oracle credentials.
#
# Example:
#   cyberark_access_members = {
#     "app-service@example.com" = { member_type = "User",  permission_set = "read_only" }
#     "dba-team"                = { member_type = "Group", permission_set = "full"      }
#   }
# ---------------------------------------------------------------------------

resource "idsec_pcloud_safe_member" "oracle_access" {
  for_each = var.cyberark_access_members

  safe_id        = local.pcloud_safe_id
  member_name    = each.key
  member_type    = each.value.member_type
  permission_set = each.value.permission_set

  depends_on = [idsec_pcloud_safe.oracle_db]
}

# ---------------------------------------------------------------------------
# Step 4 — Register a SIA strong account (PAM store type)
#
# References the account already vaulted in Step 2. The SIA strong account
# links the PAM credential to the Secure Infrastructure Access engine so
# sessions can use it for zero-standing-privilege access.
# ---------------------------------------------------------------------------

resource "idsec_sia_db_strong_accounts" "oracle_db" {
  store_type   = "pam"
  name         = "oracle-${local.db_instance_id}-${var.idsec_strong_account_name_suffix}"
  account_name = idsec_pcloud_account.oracle_db.name
  safe         = var.cyberark_safe_name

  depends_on = [idsec_pcloud_account.oracle_db]
}

# ---------------------------------------------------------------------------
# Step 5 — Create the SIA DB workspace
#
# The workspace registers the Oracle DB as a target in the SIA engine,
# associating it with the strong account and making it available for
# policy-governed access.
# ---------------------------------------------------------------------------

resource "idsec_sia_workspaces_db" "oracle_db" {
  name                        = "oracle-${local.db_instance_id}"
  configured_auth_method_type = var.idsec_db_configured_auth_method
  read_write_endpoint         = local.db_hostname
  provider_engine             = var.idsec_db_provider_engine
  port                        = local.db_port
  services                    = [local.db_name]
  secret_id                   = idsec_sia_db_strong_accounts.oracle_db.id

  depends_on = [idsec_sia_db_strong_accounts.oracle_db]
}

# ---------------------------------------------------------------------------
# Step 6 — Create the DB access policy
#
# Defines who (principals) can connect to the Oracle DB workspace and with
# what Oracle roles. Populate idsec_policy_principals in terraform.tfvars.
#
# Example:
#   idsec_policy_principals = [
#     {
#       id                    = "DBA_Role"
#       name                  = "DbaRole"
#       type                  = "ROLE"
#     },
#     {
#       id                    = "jdoe@example.com"
#       name                  = "John Doe"
#       type                  = "USER"
#       source_directory_id   = "your-directory-uuid"
#       source_directory_name = "Active Directory"
#     }
#   ]
# ---------------------------------------------------------------------------

resource "idsec_policy_db" "oracle_db" {
  metadata = {
    name        = var.idsec_policy_name
    description = "Oracle DB access policy for ${local.db_instance_id} — managed by Terraform"
    status = {
      status = "Active"
    }
    time_frame = {
      from_time = null
      to_time   = null
    }
    policy_entitlement = {
      target_category = "DB"
      location_type   = "FQDN/IP"
    }
    policy_tags = []
    time_zone   = var.idsec_policy_timezone
  }

  principals = var.idsec_policy_principals

  conditions = {
    max_session_duration = var.idsec_policy_max_session_duration
  }

  targets = {
    "FQDN/IP" = {
      instances = [
        {
          instance_name         = idsec_sia_workspaces_db.oracle_db.name
          instance_type         = "Oracle"
          instance_id           = idsec_sia_workspaces_db.oracle_db.id
          authentication_method = "db_auth"
          oracle_auth_profile = {
            dba_role     = var.idsec_policy_oracle_dba_role
            sysdba_role  = var.idsec_policy_oracle_sysdba_role
            sysoper_role = var.idsec_policy_oracle_sysoper_role
            roles        = var.idsec_policy_oracle_roles
          }
        }
      ]
    }
  }

  depends_on = [idsec_sia_workspaces_db.oracle_db]
}

# ---------------------------------------------------------------------------
# Step 7 — Register the Oracle DB hostname in the connector pool
#
# Associates the RDS FQDN with the existing connector pool so that SIA
# connectors in that pool can reach the database target.
# ---------------------------------------------------------------------------

resource "idsec_cmgr_pool_identifier" "oracle_db" {
  pool_id = var.connector_pool_id
  type    = "GENERAL_FQDN"
  value   = local.db_hostname

  depends_on = [idsec_sia_workspaces_db.oracle_db]
}

