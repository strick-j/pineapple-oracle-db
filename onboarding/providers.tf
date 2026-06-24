terraform {
  required_version = ">= 1.10.0"

  required_providers {
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.6"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.5"
    }
  }

}

# ---------------------------------------------------------------------------
# Conjur provider — IAM host role authentication (authn-iam)
#
# Authentication flow:
#   1. The EC2/ECS host running Terraform carries an AWS IAM role.
#   2. Conjur validates the AWS STS identity against its authn-iam policy.
#   3. No API key or helper script is required.
# ---------------------------------------------------------------------------
provider "conjur" {
  appliance_url = var.conjur_appliance_url
  account       = var.conjur_account
  authn_type    = var.conjur_authn_type
  service_id    = var.conjur_authn_service_id
  host_id       = var.conjur_host_id
}

# ---------------------------------------------------------------------------
# Retrieve idsec provider credentials from Conjur.
#
# Because conjur and idsec are independent providers with no circular
# dependency, Terraform can evaluate these data sources and feed their values
# directly into the idsec provider block below — no CLI or TF_VAR_ wrappers
# are needed.
# ---------------------------------------------------------------------------
data "conjur_secret" "sca_username" {
  name = var.conjur_sca_username_path
}

data "conjur_secret" "sca_password" {
  name = var.conjur_sca_password_path
}

# ---------------------------------------------------------------------------
# idsec provider — credentials sourced directly from Conjur data sources.
# ---------------------------------------------------------------------------
provider "idsec" {
  auth_method = "identity"
  username    = data.conjur_secret.sca_username.value
  secret      = data.conjur_secret.sca_password.value
}
