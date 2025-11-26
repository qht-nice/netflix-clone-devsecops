# Elastic ip
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    name= "Eip"
  }
}
# Nat_gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id    = var.public_subnet_id

  tags = {
    Name = "Nat_gateway"
  }

  depends_on    = [var.internet_gateway]
}

# Route table

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Private_RT"
  }
}

resource "aws_route_table_association" "private_subnet_rt-association" {
  subnet_id      = var.private_subnet_id
  route_table_id = aws_route_table.private_route_table.id
}