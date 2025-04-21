# Variables for AWS and Digital Ocean configuration

# AWS Configuration
variable "aws_region" {
  description = "AWS Region to deploy to"
  default     = "us-west-2"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  default     = "10.0.0.0/16"
  type        = string
}

# Digital Ocean Configuration
variable "do_token" {
  description = "Digital Ocean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "Digital Ocean region to deploy resources"
  default     = "nyc1"
  type        = string
}

variable "do_vpc_cidr" {
  description = "CIDR block for Digital Ocean VPC"
  default     = "172.16.0.0/16"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key in Digital Ocean"
  type        = string
}
