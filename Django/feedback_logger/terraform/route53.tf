resource "aws_route53_zone" "internal" {
  name = "internal"
  vpc {
    vpc_id = aws_vpc.rds.id
  }
}

resource "aws_route53_record" "rds" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "psql.internal"
  type    = "CNAME"
  ttl     = "300"
  records = [module.rds.db_instance_address]
}

resource "aws_route53_record" "redis" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "redis.internal"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_elasticache_cluster.redis.cache_nodes.0.address]
}
