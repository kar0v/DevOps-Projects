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
  security_group_ids  = [aws_security_group.bastion.id, aws_security_group.app.id]
  subnet_ids          = [aws_subnet.app-a.id, aws_subnet.app-b.id, aws_subnet.app-c.id]
  tags = {
    Name = "${local.services[count.index]}"
  }
}

# NAT GW
resource "aws_eip" "nat" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.bastion-a.id
  tags = {
    Name = "nat-gateway"
  }
}

# Private RT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.rds.id
  route {
    cidr_block = "10.200.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "rds-private-rt"
  }
}

# associate the route table with the subnets
resource "aws_route_table_association" "app-a" {
  subnet_id      = aws_subnet.app-a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app-b" {
  subnet_id      = aws_subnet.app-b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app-c" {
  subnet_id      = aws_subnet.app-c.id
  route_table_id = aws_route_table.private.id
}
