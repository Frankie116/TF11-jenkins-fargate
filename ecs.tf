# ecs.tf

resource "aws_ecs_cluster" "my-cluster" {
  name = "myapp-cluster"
}

data "template_file" "my-template-file" {
  template = file("./templates/ecs/myapp.json.tpl")

  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
  }
}

resource "aws_ecs_task_definition" "my-task-def" {
  family                   = "myapp-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.my-template-file.rendered
}

resource "aws_ecs_service" "my-service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my-cluster.id
  task_definition = aws_ecs_task_definition.my-task-def.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.my-tg.id
    container_name   = "myapp"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.my-alb-listener, aws_iam_role_policy_attachment.ecs_task_execution_role]
}