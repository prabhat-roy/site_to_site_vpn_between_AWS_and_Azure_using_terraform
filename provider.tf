terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "default"
}

provider "azurerm" {
  subscription_id = var.sub_id
  features {}
}