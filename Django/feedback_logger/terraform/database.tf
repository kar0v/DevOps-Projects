module "rds" {
  source                 = "terraform-aws-modules/rds/aws"
  version                = "6.10.0"
  engine                 = "postgres"
  engine_version         = "12.5"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  subnet_ids             = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]
  publicly_accessible    = false
  identifier             = "feedback-logger"
  vpc_security_group_ids = [aws_security_group.rds.id]
}
