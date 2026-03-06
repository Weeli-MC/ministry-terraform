resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = var.internet_vpc_id
  description = "Allow HTTP traffic from everywhere"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "external_alb" {
  name               = "external-alb-ministry"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.echoserver.arn
  }
}

resource "aws_lb_target_group" "echoserver" {
  name        = "echoserver-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.internet_vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "ministry-cluster"
}

resource "aws_iam_role" "ecs_exec" {
  name = "ministry-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = var.workload_vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.internet_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "echoserver" {
  family                   = "echoserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_exec.arn

  container_definitions = jsonencode([{
    name  = "echoserver"
    image = "registry.k8s.io/e2e-test-images/echoserver:2.5"
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
  }])
}

resource "aws_ecs_service" "echoserver" {
  name            = "echoserver"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.echoserver.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.app_subnet_id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.echoserver.arn
    container_name   = "echoserver"
    container_port   = 8080
  }
}
