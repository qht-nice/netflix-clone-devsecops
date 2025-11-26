resource "aws_security_group" "public_security_group" {
  name        = "netflix-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from specified sources"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    name = "netflix-sg"
  }
}