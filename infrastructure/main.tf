locals {
  common_tags = {
    I_Owner     = var.i_owner
    I_Purpose   = var.i_purpose
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Random master credentials
# The username suffix ensures uniqueness; the password meets CyberArk's
# complexity requirements and Oracle's password rules.
# ---------------------------------------------------------------------------

resource "random_password" "db_password" {
  # Oracle RDS passwords: max 30 chars; blocked characters: / ' " @ space &
  length           = 28
  special          = true
  override_special = "!#$%*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "random_string" "db_username_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# ---------------------------------------------------------------------------
# Oracle RDS
# ---------------------------------------------------------------------------

module "oracle_rds" {
  source = "./modules/oracle-rds"

  identifier                 = var.db_identifier
  engine                     = var.db_engine
  engine_version             = var.db_engine_version
  license_model              = var.db_license_model
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  max_allocated_storage      = var.db_max_allocated_storage
  db_name                    = var.db_name
  username                   = "admin${random_string.db_username_suffix.result}"
  password                   = random_password.db_password.result
  port                       = var.db_port
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  allowed_security_group_ids = var.allowed_security_group_ids
  multi_az                   = var.db_multi_az
  deletion_protection        = var.db_deletion_protection
  skip_final_snapshot        = var.db_skip_final_snapshot
  backup_retention_days      = var.db_backup_retention_days
  tags                       = local.common_tags
}
