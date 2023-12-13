terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  required_version = ">= 1.3.0"
}

provider "aws" {
  region  = var.aws_region
  alias   = "primary_region"
}

provider "aws" {
  region  = var.aws_region_ha
  alias   = "secondary_region"
}