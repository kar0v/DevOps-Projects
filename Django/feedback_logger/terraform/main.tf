# Create RDS VPC
resource "aws_vpc" "rds" {
  cidr_block           = "10.200.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "rds-vpc"
  }
}
# Create RDS Subnet
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
  availability_zone                           = "eu-central-1c"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "app-a"
  }
}

resource "aws_subnet" "app-b" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.200.21.0/24"
  availability_zone                           = "eu-central-1c"
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

resource "aws_security_group" "rds" {
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

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]
  tags = {
    Name = "rds-subnet-group"
  }
}

