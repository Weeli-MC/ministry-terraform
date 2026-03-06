mock_provider "aws" {}

variables {
  db_username = "admin"
  db_password = "TestPassword123!"
}

override_resource {
  target = module.compute.aws_lb.external_alb
  values = {
    arn = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:loadbalancer/app/external-alb/1234567890abcdef"
  }
}

override_resource {
  target = module.compute.aws_lb_target_group.echoserver
  values = {
    arn = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/echoserver-tg/abcdef1234567890"
  }
}

override_resource {
  target = module.compute.aws_iam_role.ecs_exec
  values = {
    arn = "arn:aws:iam::123456789012:role/ministry-ecs-exec-role"
  }
}

run "test_networking_outputs_wired_to_compute" {
  command = plan

  assert {
    condition     = module.compute.alb_dns_name != null
    error_message = "Compute module should produce an ALB DNS name"
  }
}

run "test_networking_outputs_wired_to_database" {
  command = plan

  assert {
    condition     = module.database.database_endpoint != null
    error_message = "Database module should produce a cluster endpoint"
  }
}

run "test_vpc_cidr_separation" {
  command = plan

  assert {
    condition     = module.networking.internet_vpc_cidr_block != module.networking.workload_vpc_id
    error_message = "Internet VPC and Workload VPC should have different CIDR blocks"
  }
}
