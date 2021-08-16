output "public_subnet_id" {
  value = aws_subnet.public.id
}
output "private_subnet_id" {
  value = aws_subnet.private.id
}
output "public1_subnet_id" {
  value = aws_subnet.public_1.id
}
output "private1_subnet_id" {
  value = aws_subnet.private_1.id
}
output "vpc_id" {
  value = aws_vpc.main.id
}
output "cidr" {
  value = aws_vpc.main.cidr_block
}
output "security_group_id" {
  value = aws_security_group.allow_tls.id
}

output "loadBalancer" {
  value = aws_elb.app_elb.dns_name
}

output "httpsloadBalancer" {
  value = aws_elb.https_elb.dns_name
}

