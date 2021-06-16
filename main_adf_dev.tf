#### Trial 1 ####
#terraform {
#  backend "azurerm" {
#    resource_group_name   = "<>"
#    storage_account_name  = "<>"
#    container_name        = "tfstate"
#    key                   = "terraform_dev.tfstate"
#  }
#}

#### Trial 2 ####
# terraform {
#     backend "azurerm" {
#         resource_group_name     = "iww_sandbox"
#         storage_account_name    = "opstf"
#         container_name          = "tfstatedevops"
#         # key                     = "sbx/terraform.tfstate"
#     }
# }

# provider "azurerm" {
#   version = "2.49.0"
#   features {}
#   #use_msi = true
# subscription_id = "b54182d2-60c0-4e34-b1ab-499a3394771d"

#   backend "azurerm" {
#     storage_account_name = "opstf"
#         container_name   = "tfstatedevops"
#     key                  = "prod.terraform.tfstate"
#     #subscription_id      = "b54182d2-60c0-4e34-b1ab-499a3394771d"
#     subscription_id      = "37cec637-3adc-483c-b796-63d3760f6ead"
#     tenant_id            = "e0793d39-0939-496d-b129-198edd916feb"
#   }
# }

#### Trial 3 ####
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  #subscription_id      = "37cec637-3adc-483c-b796-63d3760f6ead"
  subscription_id		= "b54182d2-60c0-4e34-b1ab-499a3394771d"
}

resource "azurerm_resource_group" "resource-group-dev" {
  name     = var.resource-group-dev
  location = var.resource-location
}

resource "azurerm_storage_account" "adf_storage" {
  #name                     = "<>"
  name					   = "adfstorageal"
  resource_group_name      = var.resource-group-dev
  location                 = var.resource-location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  tags = {
    environment = "dev"
    do          = "delete"
  }
}

resource "azurerm_storage_container" "adf_storage_source_01" {
  name                  = "adfstoragesource01"
  storage_account_name  = azurerm_storage_account.adf_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "adf_storage_target_01" {
  name                  = "adfstoragetarget01"
  storage_account_name  = azurerm_storage_account.adf_storage.name
  container_access_type = "private"
}

resource "azurerm_data_factory" "adf_test" {
  #name                = "<>"
  name				  = "adftestal"
  resource_group_name = var.resource-group-dev
  location            = var.resource-location

  github_configuration {
    account_name    = "<>"
    branch_name     = "main"
    git_url         = "https://github.com"
    repository_name = "adf_deploy_sandbox"
    root_folder     = "/"
  }

}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf_blob_link_01" {
  name                = "adfbloblink01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  connection_string   = azurerm_storage_account.adf_storage.primary_connection_string

}

resource "azurerm_data_factory_dataset_azure_blob" "adf_ds_blob_01" {
  name                = "adfdsblob01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf_blob_link_01.name
  path                = azurerm_storage_container.adf_storage_source_01.name

 }

resource "azurerm_data_factory_dataset_azure_blob" "adf_ds_blob_02" {
  name                = "adfdsblob02"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf_blob_link_01.name
  path                = azurerm_storage_container.adf_storage_target_01.name

}

resource "azurerm_data_factory_pipeline" "adf_pipeline_01" {
  name                = "adfpipeline01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
}
