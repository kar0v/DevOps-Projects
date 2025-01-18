

# resource "aws_ecs_task_definition" "debug" {
#   family                   = "debug-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = 256
#   memory                   = 512
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn

#   container_definitions = jsonencode([
#     {
#       name      = "debug"
#       image     = "amazonlinux:2" # Amazon Linux 2 for debugging
#       cpu       = 256
#       memory    = 512
#       essential = true
#       command   = ["sleep", "3600"] # Keeps the container running for an hour
#       linuxParameters = {
#         initProcessEnabled = true
#       }
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.django.name
#           awslogs-region        = local.region
#           awslogs-stream-prefix = "ecs-debug"
#         }
#       }
#     }
#   ])
# }

# resource "aws_ecs_service" "debug" {
#   name                   = "debug-service"
#   cluster                = aws_ecs_cluster.ecs.id
#   task_definition        = aws_ecs_task_definition.debug.arn
#   desired_count          = 1
#   launch_type            = "FARGATE"
#   enable_execute_command = true # Enable SSM access

#   network_configuration {
#     subnets          = [aws_subnet.app-a.id, aws_subnet.app-b.id, aws_subnet.app-c.id]
#     security_groups  = [aws_security_group.app.id]
#     assign_public_ip = false
#   }
# }


# resource "aws_security_group_rule" "allow_debug_rds" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.app.id
#   source_security_group_id = aws_security_group.app.id
# }

# resource "aws_security_group_rule" "allow_debug_redis" {
#   type                     = "ingress"
#   from_port                = 6379
#   to_port                  = 6379
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.app.id
#   source_security_group_id = aws_security_group.app.id
# }
