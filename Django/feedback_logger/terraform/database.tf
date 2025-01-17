module "rds" {
  source                 = "terraform-aws-modules/rds/aws"
  version                = "6.10.0"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  subnet_ids             = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]
  publicly_accessible    = false
  identifier             = "feedback-logger"
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  family                 = "postgres15"
  multi_az               = true
}

# Redis


resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]

  tags = {
    Name = "redis-subnet-group"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "feedback-logger"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis.id]
  port                 = 6379
  maintenance_window   = "sun:05:00-sun:06:00"
  apply_immediately    = true
  tags = {
    Name = "feedback-logger-redis"
  }

}
