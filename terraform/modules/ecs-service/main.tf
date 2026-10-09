resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name}-frontend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"
  memory                   = "256"
  execution_role_arn       = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true

      portMappings = [
        {
          containerPort = 5173
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "VITE_API_BASE_URL"
          value = var.backend_url
        }
      ]
    }
  ])

  tags = {
    Name = "${var.name}-frontend-task"
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name}-backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"
  memory                   = "256"
  execution_role_arn       = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name = "${var.name}-backend-task"
  }
}

resource "aws_ecs_service" "frontend" {
  name                 = "${var.name}-frontend-service"
  cluster              = var.cluster_arn
  task_definition      = aws_ecs_task_definition.frontend.arn
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 0
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  depends_on = [
    aws_ecs_task_definition.frontend
  ]

  tags = {
    Name = "${var.name}-frontend-service"
  }
}

resource "aws_ecs_service" "backend" {
  name                 = "${var.name}-backend-service"
  cluster              = var.cluster_arn
  task_definition      = aws_ecs_task_definition.backend.arn
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 0
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  depends_on = [
    aws_ecs_task_definition.backend
  ]

  tags = {
    Name = "${var.name}-backend-service"
  }
}