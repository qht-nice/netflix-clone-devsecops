#EC2
resource "aws_instance" "public_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [var.public_security_group.id]
  key_name = "netflix-key"

  associate_public_ip_address = true

  tags = {
    Name = "netflix-ec2"
  }
}
