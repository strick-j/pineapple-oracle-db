terraform {
  required_version = ">= 1.10.0"

  required_providers {
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.6"
    }
    cyberark = {
      source  = "cyberark/cyberark"
      version = "~> 1.0"
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
# Retrieve CyberArk Privilege Cloud service-account credentials from Conjur.
#
# NOTE — Terraform provider blocks are evaluated before data sources, so these
# values cannot directly configure the cyberark provider in the same apply run.
# The recommended pattern for CI/CD pipelines is:
#
#   export TF_VAR_cyberark_client_id=$(conjur variable get \
#     -i "$CONJUR_CYBERARK_CLIENT_ID_PATH")
#   export TF_VAR_cyberark_client_secret=$(conjur variable get \
#     -i "$CONJUR_CYBERARK_CLIENT_SECRET_PATH")
#
# The data sources below are retained for auditability and to verify the Conjur
# paths are reachable before the CyberArk resources are created.
# ---------------------------------------------------------------------------
data "conjur_secret" "cyberark_client_id" {
  name = var.conjur_cyberark_client_id_path
}

data "conjur_secret" "cyberark_client_secret" {
  name = var.conjur_cyberark_client_secret_path
}

# ---------------------------------------------------------------------------
# CyberArk Privilege Cloud provider
#
# Credentials are sourced from sensitive input variables. In CI/CD pipelines
# these are set via TF_VAR_cyberark_client_id / TF_VAR_cyberark_client_secret
# which are populated using IAM auth to Conjur (see note above).
# ---------------------------------------------------------------------------
provider "cyberark" {
  identity_url  = var.cyberark_identity_url
  pas_base_url  = var.cyberark_pas_url
  client_id     = var.cyberark_client_id
  client_secret = var.cyberark_client_secret
}
