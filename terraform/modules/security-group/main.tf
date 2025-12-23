resource "aws_security_group" "public_security_group" {
  name   = "netflix-sg"
  vpc_id = var.vpc_id

  # SSH
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr != "" ? var.allowed_ssh_cidr : var.vpc_cidr_block]
  }

  # HTTP / HTTPS
  ingress {
    description = "Allow HTTP from VPC only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow HTTPS from VPC only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Application ports
  ingress {
    description = "Allow app port 8080 from VPC only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow app port 8081 from VPC only"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow app port 9000 from VPC only"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Prometheus (default 9090)
  ingress {
    description = "Allow Prometheus from VPC only"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Node Exporter (default 9100)
  ingress {
    description = "Allow Node Exporter from VPC only"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Alertmanager (default 9093)
  ingress {
    description = "Allow Alertmanager from VPC only"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Grafana (default 3000)
  ingress {
    description = "Allow Grafana from VPC only"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    name = "netflix-sg"
  }
}