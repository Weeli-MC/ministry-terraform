variables {
  internet_vpc_id   = "vpc-12345678"
  internet_vpc_cidr = "10.0.0.0/16"
  subnet_ids        = ["subnet-1", "subnet-2"]
  workload_vpc_id   = "vpc-87654321"
  app_subnet_id     = "subnet-3"
}

run "verify_alb_configuration" {
  command = plan

  module {
    source = "./modules/compute"
  }

  assert {
    condition     = aws_lb.external_alb.internal == false
    error_message = "ALB should be external"
  }

  assert {
    condition     = aws_lb.external_alb.load_balancer_type == "application"
    error_message = "LB type should be 'application'"
  }

  assert {
    condition     = alltrue([for s in var.subnet_ids : contains(aws_lb.external_alb.subnets, s)])
    error_message = "ALB is missing required subnets"
  }

  assert {
    condition     = aws_security_group.alb_sg.vpc_id == var.internet_vpc_id
    error_message = "ALB SG is in the wrong VPC"
  }

  assert {
    condition     = one(aws_security_group.alb_sg.ingress).from_port == 80 && one(aws_security_group.alb_sg.ingress).protocol == "tcp"
    error_message = "ALB SG must allow TCP 80 ingress"
  }

  assert {
    condition     = aws_lb_listener.front_end.port == 80 && aws_lb_listener.front_end.protocol == "HTTP"
    error_message = "ALB listener config is incorrect"
  }

  assert {
    condition     = one(aws_lb_listener.front_end.default_action).type == "forward"
    error_message = "Default action must be forward"
  }
}