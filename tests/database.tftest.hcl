variables {
  workload_vpc_id         = "vpc-123"
  internet_vpc_cidr_block = "10.0.0.0/16"
  data_subnet_id          = "subnet-data-123"
  app_subnet_id           = "subnet-app-123"
  db_username             = "admin"
  db_password             = "TestPassword123!"
}

run "test_aurora_cluster_config" {
  command = plan

  module {
    source = "./modules/database"
  }

  assert {
    condition     = aws_rds_cluster.aurora_cluster.engine == "aurora-postgresql"
    error_message = "Aurora cluster should use aurora-postgresql engine"
  }

  assert {
    condition     = aws_rds_cluster.aurora_cluster.engine_mode == "provisioned"
    error_message = "Aurora cluster engine mode should be provisioned"
  }

  assert {
    condition     = aws_rds_cluster.aurora_cluster.cluster_identifier == "ministry-family-db"
    error_message = "Aurora cluster identifier should be 'ministry-family-db'"
  }

  assert {
    condition     = aws_rds_cluster.aurora_cluster.database_name == "ministryfamily"
    error_message = "Aurora cluster database name should be 'ministryfamily'"
  }

  assert {
    condition     = aws_rds_cluster.aurora_cluster.skip_final_snapshot == true
    error_message = "Aurora cluster should skip final snapshot"
  }
}

run "test_aurora_serverless_scaling" {
  command = plan

  module {
    source = "./modules/database"
  }

  assert {
    condition     = one(aws_rds_cluster.aurora_cluster.serverlessv2_scaling_configuration).min_capacity == 0.5
    error_message = "Aurora serverless v2 min capacity should be 0.5 ACU"
  }

  assert {
    condition     = one(aws_rds_cluster.aurora_cluster.serverlessv2_scaling_configuration).max_capacity == 1.0
    error_message = "Aurora serverless v2 max capacity should be 1.0 ACU"
  }
}

run "test_aurora_cluster_instance" {
  command = plan

  module {
    source = "./modules/database"
  }

  assert {
    condition     = aws_rds_cluster_instance.aurora_instance.instance_class == "db.serverless"
    error_message = "Aurora cluster instance class should be db.serverless"
  }

  assert {
    condition     = aws_rds_cluster_instance.aurora_instance.engine == "aurora-postgresql"
    error_message = "Aurora cluster instance engine should be aurora-postgresql"
  }
}

run "test_database_security_group" {
  command = plan

  module {
    source = "./modules/database"
  }

  assert {
    condition     = aws_security_group.database_sg.vpc_id == var.workload_vpc_id
    error_message = "Database security group should be in the Workload VPC"
  }

  assert {
    condition     = one(aws_security_group.database_sg.ingress).from_port == 5432
    error_message = "Database security group should allow ingress from port 5432 (PostgreSQL)"
  }

  assert {
    condition     = one(aws_security_group.database_sg.ingress).to_port == 5432
    error_message = "Database security group should allow ingress to port 5432 (PostgreSQL)"
  }

  assert {
    condition     = one(aws_security_group.database_sg.ingress).protocol == "tcp"
    error_message = "Database security group ingress should use TCP protocol"
  }

  assert {
    condition     = contains(one(aws_security_group.database_sg.ingress).cidr_blocks, var.internet_vpc_cidr_block)
    error_message = "Database security group should only allow traffic from the Internet VPC CIDR"
  }
}

run "test_db_subnet_group" {
  command = plan

  module {
    source = "./modules/database"
  }

  assert {
    condition     = aws_db_subnet_group.data_subnets.name == "main-data-subnets"
    error_message = "DB subnet group should be named 'main-data-subnets'"
  }

  assert {
    condition     = contains(tolist(aws_db_subnet_group.data_subnets.subnet_ids), var.data_subnet_id)
    error_message = "DB subnet group should include the data subnet"
  }

  assert {
    condition     = contains(tolist(aws_db_subnet_group.data_subnets.subnet_ids), var.app_subnet_id)
    error_message = "DB subnet group should include the app subnet"
  }

  assert {
    condition     = length(aws_db_subnet_group.data_subnets.subnet_ids) == 2
    error_message = "DB subnet group should contain exactly 2 subnets (data and app)"
  }
}
