provider "azurerm" {
  features {}
}

provider "shell" {
  sensitive_environment = {
    AZURE_DEVOPS_EXT_PAT = var.ado_ext_pat
  }
}

variable "ado_ext_pat" {
  description = "Azure DevOps Personal Access Token"
  type        = string
}

variable "ado_org" {
  type        = string
  description = "Azure DevOps organization"
}

variable "serviceprincipalid" {
  type        = string
  description = "Service principal ID"
}

variable "serviceprincipalkey" {
  type        = string
  description = "Service principal secret"
}

variable "azurerm_spn_tenantid" {
  type        = string
  description = "Azure Tenant ID of the service principal"
}

variable "azurerm_subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

resource "azurerm_resource_group" "demo-vmss" {
  name     = "rg-demo-azure-devops-vmss"
  location = "uksouth"
  tags     = {}
}

resource "azurerm_virtual_network" "demo-vmss" {
  name                = "vnet-demo-azure-devops-vmss"
  resource_group_name = azurerm_resource_group.demo-vmss.name
  address_space       = ["192.168.0.0/16"]
  location            = "uksouth"
  tags                = {}
}

resource "azurerm_subnet" "demo-vmss" {
  name                 = "snet-demo-azure-devops-vmss"
  resource_group_name  = azurerm_resource_group.demo-vmss.name
  address_prefixes     = ["192.168.0.0/24"]
  virtual_network_name = azurerm_virtual_network.demo-vmss.name
}

resource "azuredevops_project" "project" {
  name        = "demo-azure-devops-vmss"
  description = "Demo project for scale set agents"
  visibility  = "private"
}

resource "azuredevops_serviceendpoint_azurerm" "sub" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "demo-azure-devops-vmss"
  description           = "Managed by Terraform"
  credentials {
    serviceprincipalid  = var.serviceprincipalid
    serviceprincipalkey = var.serviceprincipalkey
  }
  azurerm_spn_tenantid      = var.azurerm_spn_tenantid
  azurerm_subscription_id   = var.azurerm_subscription_id
  azurerm_subscription_name = "demo-azure-devops-vmss"
}

module "terraform-azurerm-vmss-devops-agent" {
  source                   = "tonyskidmore/vmss-devops-agent/azurerm"
  version                  = "0.2.1"
  ado_org                  = var.ado_org
  ado_pool_name            = "demo-azure-devops-vmss"
  ado_project              = azuredevops_project.project.name
  ado_service_connection   = azuredevops_serviceendpoint_azurerm.sub.service_endpoint_name
  vmss_admin_password      = "Sup3rS3cr3tD3m4P@55"
  vmss_name                = "demo-azure-devops-vmss"
  vmss_resource_group_name = azurerm_resource_group.demo-vmss.name
  vmss_subnet_id           = azurerm_subnet.demo-vmss.id
  tags                     = {}
}
