locals {
  project            = "feedback-logger"
  region             = "eu-central-1"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  DevelopedBy        = "Krasimir Karov"
}
###########
### EFS ###
###########
resource "aws_efs_file_system" "efs" {
  creation_token = "feedback-logger"
  encrypted      = true
}

resource "aws_efs_mount_target" "efs-a" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.app-a.id
  security_groups = [aws_security_group.app.id]
}

resource "aws_efs_mount_target" "efs-b" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.app-b.id
  security_groups = [aws_security_group.app.id]
}

resource "aws_efs_mount_target" "efs-c" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.app-c.id
  security_groups = [aws_security_group.app.id]
}

resource "aws_efs_access_point" "data" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/data/efs/media"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}


###########
### ECR ###
###########

resource "aws_ecr_repository" "django" {
  name = "django"
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.rds.id
  service_name       = "com.amazonaws.${local.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app-a.id, aws_subnet.app-b.id, aws_subnet.app-c.id]
  security_group_ids = [aws_security_group.app.id]
  tags = {
    Name = "ecr-api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.rds.id
  service_name       = "com.amazonaws.${local.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app-a.id, aws_subnet.app-b.id, aws_subnet.app-c.id]
  security_group_ids = [aws_security_group.app.id]
  tags = {
    Name = "ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.rds.id
  service_name = "com.amazonaws.${local.region}.s3"
  route_table_ids = [
    aws_route_table.rds.id
  ]
  tags = {
    Name = "s3"
  }
}

resource "aws_security_group_rule" "allow_ecs_to_ecr_endpoints" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.app.id
}


##################
### Cloudwatch ###
##################

resource "aws_cloudwatch_log_group" "django" {
  name = "/ecs/feedback-logger/django"
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id             = aws_vpc.rds.id
  service_name       = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app-a.id, aws_subnet.app-b.id, aws_subnet.app-c.id]
  security_group_ids = [aws_security_group.app.id]
  tags = {
    Name = "cloudwatch"
  }
}



###########
### IAM ###
###########

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "ecs_task_execution_role_policy"
  role = aws_iam_role.ecs_task_execution_role.name

  # "*" is for debug only. With this , the EFS is loaded properly
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:SendCommand",
          "ssm:StartSession",
          "ssm:DescribeInstanceInformation",
          "*"

        ],
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeMountTargets"
        ],
        "Resource" : [
          "arn:aws:elasticfilesystem:${local.region}:${data.aws_caller_identity.current.account_id}:file-system/fs-0bc6f823d16ca38c7",
          "arn:aws:elasticfilesystem:${local.region}:${data.aws_caller_identity.current.account_id}:access-point/fsap-06a66ad3234f236a4"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::aws-ssm-${local.region}/*"
      }

    ]
  })
}


resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs_task_role_policy"
  role = aws_iam_role.ecs_task_role.name

  # "*" is for debug only. With this , the EFS is loaded properly
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:SendCommand",
          "ssm:StartSession",
          "ssm:DescribeInstanceInformation",
          "*"


        ],
        Resource = "*"
      }
    ]
  })
}

###########
### ALB ###
###########

resource "aws_lb" "django" {
  name               = "django"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = [aws_subnet.bastion-a.id, aws_subnet.bastion-b.id, aws_subnet.bastion-c.id]
}
resource "aws_lb_target_group" "django" {
  name        = "django"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = aws_vpc.rds.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "django" {
  load_balancer_arn = aws_lb.django.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django.arn
  }
}

# security group for ALB
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.rds.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


###########
### ECS ###
###########

resource "aws_ecs_cluster" "ecs" {
  name = "webapp"

}

data "aws_caller_identity" "current" {}


resource "aws_ecs_task_definition" "django" {
  family = "django"
  container_definitions = jsonencode([
    {
      name      = "feedback-logger"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/django:latest"
      cpu       = 256
      memory    = 512
      essential = true

      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.django.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])


  # volume {
  #   name = "service-storage"

  #   efs_volume_configuration {
  #     file_system_id          = aws_efs_file_system.efs.id
  #     transit_encryption      = "ENABLED"
  #     transit_encryption_port = 2999
  #     authorization_config {
  #       access_point_id = aws_efs_access_point.data.id
  #       iam             = "ENABLED"
  #     }
  #   }
  # }

  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
}


resource "aws_ecs_service" "django" {
  name            = "django"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.django.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.django.arn
    container_name   = "feedback-logger"
    container_port   = 8000
  }
  network_configuration {
    subnets          = [aws_subnet.app-a.id, aws_subnet.app-b.id, aws_subnet.app-c.id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }
  enable_execute_command = true
}
