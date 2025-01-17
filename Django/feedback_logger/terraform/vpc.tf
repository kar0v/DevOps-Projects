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

