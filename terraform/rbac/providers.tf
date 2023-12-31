terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread        = true
  skip_provider_registration = true
}
