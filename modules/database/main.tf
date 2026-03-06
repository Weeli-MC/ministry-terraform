resource "aws_db_subnet_group" "data_subnets" {
  name       = "main-data-subnets-ministry"
  subnet_ids = [var.data_subnet_id, var.app_subnet_id]
  tags       = { Name = "Aurora-Subnet-Group" }
}

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  vpc_id      = var.workload_vpc_id
  description = "Allow traffic from the App only"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.internet_vpc_cidr_block]
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier     = "ministry-family-db"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "15"
  database_name          = "ministryfamily"
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.data_subnets.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  skip_final_snapshot    = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}
