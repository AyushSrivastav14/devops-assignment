resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024 # 1 vCPU
  memory                   = 2048 # 2 GB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  # Translating the docker-compose services into ECS container definitions
  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "redis:alpine"
      essential = true
      portMappings = [{ containerPort = 6379 }]
    },
    {
      name      = "backend"
      image     = "${var.image_base_identity}/task-notifier-backend:latest"
      essential = true
      environment = [
        { name = "REDIS_URL", value = "redis://localhost:6379/0" } 
      ]
    },
    {
      name      = "worker"
      image     = "${var.image_base_identity}/task-notifier-backend:latest"
      essential = true
      command   = ["celery", "-A", "worker.celery", "worker", "--loglevel=info"]
      environment = [
        { name = "REDIS_URL", value = "redis://localhost:6379/0" }
      ]
    },
    {
      name      = "frontend"
      image     = "${var.image_base_identity}/task-notifier-frontend:latest"
      essential = true
      portMappings = [{ containerPort = var.app_port }]
      environment = [
        { name = "BACKEND_HOST", value = "127.0.0.1" }
      ]
      dependsOn = [
        { containerName = "backend", condition = "START" }
      ]
    }
  ])
}
