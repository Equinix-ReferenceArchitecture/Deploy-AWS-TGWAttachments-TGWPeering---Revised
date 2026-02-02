
terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = "2.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.1"

    }  
  }
}


provider "aws" {
  region = var.primary_aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias = "secondary"
  region     = var.secondary_aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
} 

