# ado-vmss-simple-demo

## Overview

This repository contains a simple standalone example of using the [terraform-azurerm-vmss-devops-agent](https://github.com/tonyskidmore/terraform-azurerm-vmss-devops-agent) Terraform module.  

When the prerequisites are in place and the below Terraform workflow is executed the following will be created:

* Azure DevOps project.
* Azure DevOps Azure Resource Manager Service Connection to the target Azure Subscription.
* Azure DevOps [Azure virtual machine scale set agent pool](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops) linked to the above Azure VMSS.
* Azure Resource Group called `rg-demo-azure-devops-vmss`
* Azure Virtual network and subnet, in the above resource group.
* Azure Ubuntu 20.04 Linux [Virtual Machine Scale Set](https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview)(VMSS).


## Requirements

You will need the following to be able to deploy the resources for this demo:

* An Azure subscription.
  _Note:_ you can get started with a [Azure free account][azure-free]

* An [Azure DevOps][azdo] [Organization][azdo-org].
  _Note:_ you can sign up for free in the above link.


## Prerequisites

This example requires environment variables to be exported to supply the necessary values for resources to be created in Azure and Azure DevOps.

1. Obtain the Azure Subscription ID that will be used for the test.

2. Create an Azure Service Principal, if you have permissions to do so in your Azure Active Directory.  If you do not have permissions you will need to request the creation of one or using an existing one.  If you are not creating the service principal using the az cli command below ensure that RBAC permissions have been given to the Subscription for the service principal i.e. Owner or Contributor + User Access Administrator.
[az ad sp create-for-rbac](https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create-for-rbac)

Example:

````bash

az ad sp create-for-rbac -n demo-sp --role Owner --scopes /subscriptions/00000000-0000-0000-0000-000000000000
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "demo-sp",
  "password": "ckusfcc8ope2soot1yuovmdvlgtfgj9nio2orfwyvv5jsgcnwwga",
  "tenant": "00000000-0000-0000-0000-000000000000"
}

````

Replacing `/subscriptions/00000000-0000-0000-0000-000000000000` with your target Azure subscription ID.

3. Export the environment variables used by Terraform to authenticate to Azure using the outputs from the above `az` CLI command.

````bash

 export ARM_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
 export ARM_TENANT_ID=00000000-0000-0000-0000-000000000000
 export ARM_CLIENT_ID=00000000-0000-0000-0000-000000000000
 export ARM_CLIENT_SECRET=<secret-here>

````
Replace the above Terraform environment variables example values with those taken from the output of the `az ad sp create-for-rbac` command, as indicated in the table below (and `ARM_SUBSCRIPTION_ID` with the value of your target Azure subscription):

| Terraform environment | Output from Azure CLI |
|-----------------------|-----------------------|
| ARM_CLIENT_ID         | appId                 |
| ARM_CLIENT_SECRET     | password              |
| ARM_TENANT_ID         | tenant                |


4. [Create an Azure DevOps Personal Access Token](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows#create-a-pat)(PAT) with Full Access to the Organization.  

5. Export the values required by the Terraform Azure DevOps provider and the [terraform-azurerm-vmss-devops-agent](https://github.com/tonyskidmore/terraform-azurerm-vmss-devops-agent) Terraform module.
Replacing the examples shown below to use your Azure DevOps PAT token and Azure DevOps organization URL.

````bash

 export AZDO_PERSONAL_ACCESS_TOKEN="ckusfcc8ope2soot1yuovmdvlgtfgj9nio2orfwyvv5jsgcnwwga"
export AZDO_ORG_SERVICE_URL="https://dev.azure.com/tonyskidmore"

````

6. Export the remainder of the required Terraform variables used in this example:

````bash

export TF_VAR_ado_org="$AZDO_ORG_SERVICE_URL"
export TF_VAR_ado_ext_pat="$AZDO_PERSONAL_ACCESS_TOKEN"
export TF_VAR_serviceprincipalid="$ARM_CLIENT_ID"
export TF_VAR_serviceprincipalkey="$ARM_CLIENT_SECRET"
export TF_VAR_azurerm_spn_tenantid="$ARM_TENANT_ID"
export TF_VAR_azurerm_subscription_id="$ARM_SUBSCRIPTION_ID"

````

7. A version of the [Terraform CLI](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) installed.


## Terraform workflow

Once the prerequisites mentioned above are in place complete the following on a Linux based system, with the following commands installed.  For example, [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about) or [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/overview) (which has all the software prerequisites already installed):

* cat
* curl
* sed
* jq

To create the Azure DevOps Project, Service connection, self-hosted scale set agent pool and the Azure VMSS perform the following:

````bash

git clone https://github.com/tonyskidmore/ado-vmss-simple-demo.git
cd ado-vmss-simple-demo
terraform init
terraform plan -out tfplan
terraform apply tfplan

````

This should have created the resources mentioned in the overview and you can now go ahead and open up the `demo-azure-devops-vmss` project and initialize the `demo-azure-devops-vmss` repo in Repos and create a Starter pipeline in Pipelines.  The below is an updated example using the `demo-azure-devops-vmss` pool name created by this example.

````yaml

# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml

trigger:
- main

pool:
  name: demo-azure-devops-vmss

steps:
- script: echo Hello, world!
  displayName: 'Run a one-line script'

- script: |
    echo Add other tasks to build, test, and deploy your project.
    echo See https://aka.ms/yaml
  displayName: 'Run a multi-line script'

````

When the above pipeline is run check the Instances in the `demo-azure-devops-vmss` VMSS in the `rg-demo-azure-devops-vmss` resource group.  Note that it scales up shortly after running the pipeline above and will scale down to zero after about 15 minutes, due to the default settings of the Terraform module.  

Once testing is complete destroy the deployment as follows:

````bash

terraform plan -destroy -out tfplan
terraform apply tfplan

````

_Note_: A more comprehensive example can be found in the `terraform-azurerm-vmss-devops-agent` module [demo_environment](https://github.com/tonyskidmore/terraform-azurerm-vmss-devops-agent) directory.
