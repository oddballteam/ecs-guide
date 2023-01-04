# Default Network Resources
# Works different than normal resources
# adopts the default vpc/subnet for tf to reference
# will not create/destroy despite what the cli suggests
resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "east_1a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "east_1b" {
  availability_zone = "us-east-1b"
}


# application load balancer
resource "aws_lb" "main" {
  name               = "${var.name}-test"
  security_groups    = [aws_security_group.main.id]
  subnets            = [aws_default_subnet.east_1a.id, aws_default_subnet.east_1b.id]
}

# load balancer target group
resource "aws_lb_target_group" "main" {
  name        = "${var.name}-test"
  port        = var.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default.id
}

# load balancer incoming port and action
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-test"
}

resource "aws_iam_role" "ecs_assume" {
  name               = "${var.name}-test-ecs-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# allows log creation, will work with ecs task agents despite lambda name
resource "aws_iam_role_policy_attachment" "logs_create" {
  role       = aws_iam_role.ecs_assume.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# gives full ECR permissions
resource "aws_iam_role_policy_attachment" "ecr_full_permission" {
  role       = aws_iam_role.ecs_assume.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# task definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  # role that the Amazon ECS container agent and the Docker daemon can assume.
  execution_role_arn       = aws_iam_role.ecs_assume.arn
  cpu                      = 256 # 256 minimum
  memory                   = 512 # 512 minimum (MiB)
  container_definitions    = <<DEFINITION
    [{
      "name": "${var.name}-test",
      "image": "${var.image}",
      "memoryReservation": 128,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/ecs/${var.name}-test",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      },
      "portMappings": [{
        "containerPort": ${var.port}
      }]
    }]
  DEFINITION
}

data "external" "my_ip" {
  program = ["curl", "https://ipinfo.io"]
}

# security group
resource "aws_security_group" "main" {
  name = "${var.name}-test"
  description = "Temporary group made from a guide to new ECS infrastructure"
  vpc_id      = aws_default_vpc.default.id
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "TCP"
    cidr_blocks = ["${aws_default_vpc.default.cidr_block}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# service
resource "aws_ecs_service" "main" {
  name            = "${var.name}-test"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.name
    container_port   = var.port
  }
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.main.id]
    subnets          = [aws_default_subnet.east_1a.id, aws_default_subnet.east_1b.id]
  }
}

variable "name" {
}

variable "port" {
  default = 80
}

variable "image" {
  default = "nginx:latest"
}