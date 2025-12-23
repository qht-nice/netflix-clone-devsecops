variable "vpc_id" {}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for internal access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access (default: VPC CIDR for security)"
  type        = string
  default     = ""
}