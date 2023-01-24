terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.3.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "~>1.7.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.1.0"
    }
  }
  required_version = ">= 1.0.0"
}
