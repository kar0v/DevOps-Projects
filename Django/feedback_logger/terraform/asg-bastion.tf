
resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSM_EC2_Instance_Profile"
  role = aws_iam_role.ssm_role.name
}


# AMI

data "aws_ami" "amzn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]

}

# SQS For autoscaling

resource "aws_sqs_queue" "autoscaling" {
  name = "autoscaling"
}


# KEY


resource "tls_private_key" "oei-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "oei-key-pair" {
  key_name   = "oei-key-pair"
  public_key = tls_private_key.oei-key.public_key_openssh
}


# LT, ASG for bastion
resource "aws_launch_template" "bastion" {
  name          = "bastion"
  image_id      = data.aws_ami.amzn.id
  instance_type = "t2.micro"
  key_name      = "oei-key-pair"
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_instance_profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.bastion.id, aws_security_group.app.id, aws_security_group.rds.id]

  }
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "bastion"
  vpc_zone_identifier = [
    aws_subnet.bastion-a.id,
    aws_subnet.bastion-b.id,
    aws_subnet.bastion-c.id
  ]
  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }
  min_size                  = 3
  max_size                  = 3
  desired_capacity          = 3
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "bastion"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  autoscaling_group_name = aws_autoscaling_group.bastion.name
  name                   = "cpu_scaling"
  policy_type            = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 80
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
      }
      customized_scaling_metric_specification {
        metric_data_queries {
          id = "scaling"
          metric_stat {
            metric {
              metric_name = "CPUUtilization"
              namespace   = "AWS/EC2"
              dimensions {
                name  = "AutoScalingGroupName"
                value = aws_autoscaling_group.bastion.name
              }
            }
            stat = "Average"
          }
        }
      }
    }
  }
}

