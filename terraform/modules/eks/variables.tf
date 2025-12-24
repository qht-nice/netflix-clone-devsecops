variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "netflix-eks"
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for EKS control plane and node groups (at least two in different AZs)"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "c7i-flex.large"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for allowing Prometheus scraping"
  type        = string
}

variable "prometheus_security_group_id" {
  description = "Security group ID of Prometheus EC2 instance"
  type        = string
}

