terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.11"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "ap-southeast-2"
}

# Key
resource "aws_key_pair" "TF_key" {
  key_name   = "netflix-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "TF-key" {
  content         = tls_private_key.rsa.private_key_pem
  filename        = "netflix-key.pem"
  file_permission = "0400"
}

# VPC
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  cidr_public_subnet = var.cidr_public_subnet
}

#Security Groups
module "security_group" {
  source = "./modules/security-group"
  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = var.vpc_cidr_block
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

#EC2
module "ec2" {
  source = "./modules/ec2"
  ami = var.ami
  instance_type = var.instance_type
  public_subnet_id = module.vpc.public_subnet_id
  public_security_group = module.security_group.public_security_group
}

module "prometheus_ec2" {
  source                = "./modules/ec2"
  ami                   = var.ami
  instance_type         = "t3.small"
  public_subnet_id      = module.vpc.public_subnet_id
  public_security_group = module.security_group.public_security_group
  name                  = "prometheus-server"
}

