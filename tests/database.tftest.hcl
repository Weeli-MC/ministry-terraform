variables {
  workload_vpc_id         = "vpc-123"
  internet_vpc_cidr_block = "10.0.0.0/16"
  data_subnet_id          = "subnet-data-123"
  app_subnet_id           = "subnet-app-123"
  db_username             = "admin"
  db_password             = "TestPassword123!"
}

run "verify_aurora_stack" {
  command = plan

  module {
    source = "./modules/database"
  }

  assert {
    condition = alltrue([
      aws_rds_cluster.aurora_cluster.engine == "aurora-postgresql",
      aws_rds_cluster.aurora_cluster.engine_mode == "provisioned",
      aws_rds_cluster.aurora_cluster.cluster_identifier == "ministry-family-db"
    ])
    error_message = "Aurora cluster core configuration (engine, mode, or ID) is incorrect"
  }

  assert {
    condition     = one(aws_rds_cluster.aurora_cluster.serverlessv2_scaling_configuration).min_capacity == 0.5 && one(aws_rds_cluster.aurora_cluster.serverlessv2_scaling_configuration).max_capacity == 1.0
    error_message = "Serverless v2 scaling must be between 0.5 and 1.0 ACU"
  }

  assert {
    condition     = aws_rds_cluster_instance.aurora_instance.instance_class == "db.serverless"
    error_message = "Aurora instance must use db.serverless class"
  }

  assert {
    condition     = aws_security_group.database_sg.vpc_id == var.workload_vpc_id
    error_message = "Database SG is in the wrong VPC"
  }

  assert {
    condition = (
      one(aws_security_group.database_sg.ingress).from_port == 5432 &&
      one(aws_security_group.database_sg.ingress).protocol == "tcp" &&
      contains(one(aws_security_group.database_sg.ingress).cidr_blocks, var.internet_vpc_cidr_block)
    )
    error_message = "Inbound rules must restrict PostgreSQL (5432) to the Internet VPC CIDR"
  }

  assert {
    condition     = length(aws_db_subnet_group.data_subnets.subnet_ids) == 2
    error_message = "Subnet group must contain exactly 2 subnets"
  }

  assert {
    condition     = alltrue([for s in [var.data_subnet_id, var.app_subnet_id] : contains(aws_db_subnet_group.data_subnets.subnet_ids, s)])
    error_message = "Subnet group is missing the required data or app subnets"
  }
}