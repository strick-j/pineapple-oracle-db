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

  # Partial backend configuration — supply values at init time:
  #   terraform init -backend-config=backend.hcl
  # See backend.hcl.example for required keys.
  backend "s3" {}
}

# ---------------------------------------------------------------------------
# Conjur provider — IAM host role authentication (authn-iam)
#
# Authentication flow:
#   1. The host running Terraform carries an AWS IAM role.
#   2. The Conjur authn-iam service validates that role against its policy.
#   3. No API key or helper script is required.
#
# Required environment variables:
#   CONJUR_AUTHN_IAM_SERVICE_ID  — authn-iam service ID configured in your
#                                  Conjur policy (commonly "aws").
#
# Provider reads CONJUR_APPLIANCE_URL / CONJUR_ACCOUNT / CONJUR_AUTHN_LOGIN
# from the environment if the variables below are left empty.
# ---------------------------------------------------------------------------
provider "conjur" {
  appliance_url = var.conjur_url
  account       = var.conjur_account
  login         = var.conjur_authn_login
  # api_key is intentionally omitted — IAM auth uses the AWS credential chain.
}

# ---------------------------------------------------------------------------
# Retrieve idsec provider credentials from Conjur.
#
# NOTE — Terraform provider blocks are evaluated before data sources, so these
# values cannot directly configure the idsec provider in the same apply run.
# The recommended pattern for CI/CD pipelines is:
#
#   export TF_VAR_idsec_username=$(conjur variable get \
#     -i "$CONJUR_IDSEC_USERNAME_PATH")
#   export TF_VAR_idsec_secret=$(conjur variable get \
#     -i "$CONJUR_IDSEC_SECRET_PATH")
#
# The data sources below verify the Conjur paths are reachable before any
# idsec resources are created.
# ---------------------------------------------------------------------------
data "conjur_secret" "idsec_username" {
  name = var.conjur_idsec_username_path
}

data "conjur_secret" "idsec_secret" {
  name = var.conjur_idsec_secret_path
}

# ---------------------------------------------------------------------------
# idsec provider — CyberArk Identity authentication
#
# Credentials are sourced from sensitive input variables. In CI/CD pipelines
# these are set via TF_VAR_idsec_username / TF_VAR_idsec_secret which are
# populated using IAM auth to Conjur (see note above).
# ---------------------------------------------------------------------------
provider "idsec" {
  auth_method = "identity"
  username    = var.idsec_username
  secret      = var.idsec_secret
}
