# Provider configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.35"
    }
  }
  required_version = ">= 1.3.2"
}

# AWS Provider
provider "aws" {
  region = var.aws_region
  # AWS credentials will be sourced from environment variables or ~/.aws/credentials
}

# Digital Ocean Provider
provider "digitalocean" {
  token = var.do_token
}
