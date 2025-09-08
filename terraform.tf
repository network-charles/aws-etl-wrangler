terraform {
  backend "s3" {
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.12.0"
    }
  }
}

# configure the AWS provider
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Provisioned = "Terraform"
    }
  }
}
