run "test_alb_is_external" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    internet_vpc_id = "vpc-12345678"
    subnet_ids      = ["subnet-1", "subnet-2"]
  }

  assert {
    condition     = aws_lb.external_alb.internal == false
    error_message = "ALB should be external (internal = false)"
  }

  assert {
    condition     = aws_lb.external_alb.load_balancer_type == "application"
    error_message = "Load balancer type should be 'application'"
  }

  assert {
    condition     = aws_lb.external_alb.name == "external-alb"
    error_message = "ALB should be named 'external-alb'"
  }
}

run "test_alb_security_group" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    internet_vpc_id = "vpc-12345678"
    subnet_ids      = ["subnet-1", "subnet-2"]
  }

  assert {
    condition     = aws_security_group.alb_sg.vpc_id == var.internet_vpc_id
    error_message = "ALB security group should be in the Internet VPC"
  }

  assert {
    condition     = one(aws_security_group.alb_sg.ingress).from_port == 80
    error_message = "ALB security group should allow ingress from port 80"
  }

  assert {
    condition     = one(aws_security_group.alb_sg.ingress).to_port == 80
    error_message = "ALB security group should allow ingress to port 80"
  }

  assert {
    condition     = one(aws_security_group.alb_sg.ingress).protocol == "tcp"
    error_message = "ALB security group ingress should use TCP protocol"
  }

  assert {
    condition     = contains(one(aws_security_group.alb_sg.ingress).cidr_blocks, "0.0.0.0/0")
    error_message = "ALB security group should allow HTTP traffic from all IPs (0.0.0.0/0)"
  }

  assert {
    condition     = one(aws_security_group.alb_sg.egress).protocol == "-1"
    error_message = "ALB security group should allow all outbound traffic"
  }

  assert {
    condition     = contains(one(aws_security_group.alb_sg.egress).cidr_blocks, "0.0.0.0/0")
    error_message = "ALB security group should allow all outbound traffic to all IPs"
  }
}

run "test_alb_listener" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    internet_vpc_id = "vpc-12345678"
    subnet_ids      = ["subnet-1", "subnet-2"]
  }

  assert {
    condition     = aws_lb_listener.front_end.port == 80
    error_message = "ALB listener should be on port 80"
  }

  assert {
    condition     = aws_lb_listener.front_end.protocol == "HTTP"
    error_message = "ALB listener should use HTTP protocol"
  }

  assert {
    condition     = one(aws_lb_listener.front_end.default_action).type == "fixed-response"
    error_message = "ALB listener default action should be a fixed-response"
  }

  assert {
    condition     = one(one(aws_lb_listener.front_end.default_action).fixed_response).status_code == "503"
    error_message = "ALB listener default fixed-response status code should be 503"
  }

  assert {
    condition     = one(one(aws_lb_listener.front_end.default_action).fixed_response).content_type == "text/plain"
    error_message = "ALB listener default fixed-response content type should be text/plain"
  }
}

run "test_alb_uses_correct_subnets" {
  command = plan

  module {
    source = "./modules/compute"
  }

  variables {
    internet_vpc_id = "vpc-12345678"
    subnet_ids      = ["subnet-1", "subnet-2"]
  }

  assert {
    condition     = length(aws_lb.external_alb.subnets) == 2
    error_message = "ALB should be deployed across 2 subnets"
  }

  assert {
    condition     = contains(tolist(aws_lb.external_alb.subnets), "subnet-1")
    error_message = "ALB subnets should include subnet-1"
  }

  assert {
    condition     = contains(tolist(aws_lb.external_alb.subnets), "subnet-2")
    error_message = "ALB subnets should include subnet-2"
  }
}
