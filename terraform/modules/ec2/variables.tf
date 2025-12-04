variable "public_subnet_id" {}
variable "ami" {}
variable "instance_type" {}
variable "public_security_group" {}

variable "name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "netflix-ec2"
}