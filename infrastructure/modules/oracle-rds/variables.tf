variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "engine" {
  description = "Oracle RDS engine identifier"
  type        = string
  default     = "oracle-se2"
}

variable "engine_version" {
  description = "Oracle engine version"
  type        = string
}

variable "license_model" {
  description = "Oracle license model"
  type        = string
  default     = "license-included"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
}

variable "max_allocated_storage" {
  description = "Upper limit for autoscaling storage in GiB (0 = disabled)"
  type        = number
  default     = 0
}

variable "db_name" {
  description = "Oracle SID"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Oracle listener port"
  type        = number
  default     = 1521
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the Oracle listener"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to reach the Oracle listener"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all module resources"
  type        = map(string)
  default     = {}
}
