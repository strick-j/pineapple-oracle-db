resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnet-group"
  description = "Subnet group for ${var.identifier} Oracle RDS instance"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  license_model  = var.license_model

  # Compute / storage
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database identity
  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.port

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  # High availability
  multi_az = var.multi_az

  # Lifecycle
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"
  copy_tags_to_snapshot     = true

  # Maintenance / backups
  backup_retention_period    = var.backup_retention_days
  backup_window              = "03:00-04:00"
  maintenance_window         = "sun:04:30-sun:05:30"
  auto_minor_version_upgrade = false
  apply_immediately          = false

  performance_insights_enabled = false

  tags = merge(var.tags, {
    Name = var.identifier
  })

  lifecycle {
    # Ignore password changes — CyberArk CPM owns rotation after initial creation.
    ignore_changes = [password]
  }
}
