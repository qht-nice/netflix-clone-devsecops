variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "cidr_private_subnet" {
  default = "10.0.2.0/24"
}
variable "cidr_public_subnet" {
  default = "10.0.1.0/24"
}
variable "cidr_public_subnet_b" {
  default = "10.0.3.0/24"
}
variable "ami" {
  default     = "ami-0eeab253db7e765a9"
  description = "AMI ID for EC2 instances"
}
variable "instance_type" {
  default = "m7i-flex.large"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = ""
}

variable "webhook_cidrs" {
  description = "CIDR blocks allowed to reach webhook port 8080 (e.g., GitHub webhook IP ranges)."
  type        = list(string)
  default     = []
}

