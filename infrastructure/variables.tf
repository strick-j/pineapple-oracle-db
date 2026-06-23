# ---------------------------------------------------------------------------
# AWS & General
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-2"
}

variable "i_owner" {
  description = "Owner identifier applied to the I_Owner tag on all created resources"
  type        = string
}

variable "i_purpose" {
  description = "Purpose identifier applied to the I_Purpose tag on all created resources"
  type        = string
}

variable "project" {
  description = "Project name applied to the Project tag on all created resources"
  type        = string
  default     = "pineapple-oracle-db"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------------------------
# Network — existing VPC / Subnets
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the existing VPC where the Oracle DB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS DB subnet group (minimum two AZs recommended)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitted to reach the Oracle listener port"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "IDs of security groups whose members are permitted to reach the Oracle listener port"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Oracle RDS
# ---------------------------------------------------------------------------

variable "db_identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
  default     = "pineapple-oracle-db"
}

variable "db_engine" {
  description = "Oracle RDS engine: oracle-se2 (license-included) or oracle-ee (BYOL)"
  type        = string
  default     = "oracle-se2"

  validation {
    condition     = contains(["oracle-se2", "oracle-se2-cdb", "oracle-ee", "oracle-ee-cdb"], var.db_engine)
    error_message = "db_engine must be one of: oracle-se2, oracle-se2-cdb, oracle-ee, oracle-ee-cdb."
  }
}

variable "db_engine_version" {
  description = "Oracle engine version for Amazon RDS (Oracle 19c recommended)"
  type        = string
  default     = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
}

variable "db_instance_class" {
  description = "RDS instance class (db.t3.medium minimum for Oracle)"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 50
}

variable "db_max_allocated_storage" {
  description = "Upper limit for automatic storage scaling in GiB (0 = disable autoscaling)"
  type        = number
  default     = 200
}

variable "db_name" {
  description = "Oracle database SID / System Identifier (max 8 chars, letters and numbers only)"
  type        = string
  default     = "ORCL"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,7}$", var.db_name))
    error_message = "db_name must start with a letter, contain only letters and numbers, and be 8 characters or fewer."
  }
}

variable "db_port" {
  description = "Oracle listener port"
  type        = number
  default     = 1521
}

variable "db_license_model" {
  description = "Oracle license model: license-included (SE2 only) or bring-your-own-license"
  type        = string
  default     = "license-included"

  validation {
    condition     = contains(["license-included", "bring-your-own-license"], var.db_license_model)
    error_message = "db_license_model must be 'license-included' or 'bring-your-own-license'."
  }
}

variable "db_multi_az" {
  description = "Deploy the RDS instance across multiple Availability Zones"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when the instance is deleted (set false for production)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}
