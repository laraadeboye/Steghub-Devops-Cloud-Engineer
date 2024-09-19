variable "region" {
  description = "Region to deploy AWS VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Cidr block for VPC"
  type        = string
}

variable "env_prefix" {
  description = "Prefix for environment-specific resource names"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "ports" {
  description = "List of ports to allow inbound traffic"
  type        = list(number)
}

variable "specific_ssh_ip" {
  description = "Specific IP address allowed for SSH access"
  type        = string
}

variable "public_key_location" {
  description = "ssh public key location"
  type        = string
}