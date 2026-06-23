terraform {
  backend "s3" {
    bucket       = "your-terraform-state-bucket"
    key          = "pineapple-oracle-db/onboarding/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
