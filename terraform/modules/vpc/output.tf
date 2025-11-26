output "vpc_id" {
    value = aws_vpc.vpc.id
}
output "public_subnet_id" {
    value = aws_subnet.public_subnet.id
}
output "internet_gateway" {
    value = aws_internet_gateway.gw
}