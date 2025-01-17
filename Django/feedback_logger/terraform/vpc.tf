resource "aws_vpc" "rds" {
  cidr_block           = "10.200.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "rds-vpc"
  }
}
resource "aws_subnet" "rds-a" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.10.0/24"
  availability_zone                           = "eu-central-1a"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "rds-a"
  }
}
resource "aws_subnet" "rds-b" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.11.0/24"
  availability_zone                           = "eu-central-1b"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "rds-b"
  }
}
resource "aws_subnet" "rds-c" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.12.0/24"
  availability_zone                           = "eu-central-1c"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "rds-c"
  }
}

resource "aws_subnet" "app-a" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.20.0/24"
  availability_zone                           = "eu-central-1a"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "app-a"
  }
}

resource "aws_subnet" "app-b" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.21.0/24"
  availability_zone                           = "eu-central-1b"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "app-b"
  }
}

resource "aws_subnet" "app-c" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.22.0/24"
  availability_zone                           = "eu-central-1c"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "app-c"
  }
}


resource "aws_subnet" "bastion-a" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.30.0/24"
  availability_zone                           = "eu-central-1a"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "bastion-a"
  }
}

resource "aws_subnet" "bastion-b" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.31.0/24"
  availability_zone                           = "eu-central-1b"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "bastion-b"
  }
}

resource "aws_subnet" "bastion-c" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.32.0/24"
  availability_zone                           = "eu-central-1c"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "bastion-c"
  }
}


# internet gateway
resource "aws_internet_gateway" "rds" {
  vpc_id = aws_vpc.rds.id
  tags = {
    Name = "rds-igw"
  }
}

resource "aws_route_table" "rds" {
  vpc_id = aws_vpc.rds.id
  route {
    cidr_block = "10.200.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds.id
  }
  tags = {
    Name = "rds-rt"
  }
}

resource "aws_main_route_table_association" "rds" {
  vpc_id         = aws_vpc.rds.id
  route_table_id = aws_route_table.rds.id
}

resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.rds.id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  tags = {
    Name = "rds-sg"
  }
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.rds.id
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    self      = true
  }
  tags = {
    Name = "app-sg"
  }
}

resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.rds.id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips

  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    self      = true
  }
  tags = {
    Name = "bastion-sg"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis" {
  name   = "redis-sg"
  vpc_id = aws_vpc.rds.id
  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app-a.cidr_block, aws_subnet.app-b.cidr_block, aws_subnet.app-c.cidr_block]
  }
  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app-a.cidr_block, aws_subnet.app-b.cidr_block, aws_subnet.app-c.cidr_block]
  }


  tags = {
    Name = "app-sg"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]
  tags = {
    Name = "rds-subnet-group"
  }
}



# endpoints for SSM

locals {
  services = ["com.amazonaws.eu-central-1.ssm", "com.amazonaws.eu-central-1.ssmmessages", "com.amazonaws.eu-central-1.ec2messages"]
}
resource "aws_vpc_endpoint" "ssm" {
  count               = length(local.services)
  vpc_id              = aws_vpc.rds.id
  service_name        = local.services[count.index]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.bastion.id]
  subnet_ids          = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]
  tags = {
    Name = "${local.services[count.index]}"
  }
}
