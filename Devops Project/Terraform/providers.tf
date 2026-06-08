terraform {
  backend "s3" {
    bucket  = "segev-tfstate-project-9988" # חייב להיות תואם למשתנה ב-project.sh
    key     = "prod/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.23.0"
    }
  }
  required_version = ">= 1.14"
}

provider "aws" {
  region = "eu-west-1"
}