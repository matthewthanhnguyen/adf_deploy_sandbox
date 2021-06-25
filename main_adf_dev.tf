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
  subscription_id		= var.subscription-id
}

resource "azurerm_resource_group" "resource-group-dev" {
  name     = var.resource-group-dev
  location = var.resource-location
}

################################ Storage ################################
resource "azurerm_storage_account" "adf_storage" {
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
  name                = "adftestal"
  resource_group_name = var.resource-group-dev
  location            = var.resource-location

  github_configuration {
    account_name    = var.github-account-name
    branch_name     = var.github-branch-name
    git_url         = var.github-git-url
    repository_name = var.github-repository-name
    root_folder     = var.github-root-folder
  }
}

################################ ADF Datasets ################################
##### Linked Service for Blob/Datalake Storage #####
resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf_blob_link_01" {
  name                = "adfbloblink01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  connection_string   = azurerm_storage_account.adf_storage.primary_connection_string
}

##### Blob/Datalake Storage #####
resource "azurerm_data_factory_dataset_azure_blob" "adf_ds_blob_01" {
  name                = "adfdsblob01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf_blob_link_01.name
  path                = azurerm_storage_container.adf_storage_source_01.name
}

##### Linked Service for CSV/Local Storage, HTTP, JSON, Parquet #####
resource "azurerm_data_factory_linked_service_web" "adf_link_service_web" {
  name                = "adflinkserviceweb"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  authentication_type = "Anonymous"
  url                 = "https://www.google.com"
}

##### CSV/Local Storage #####
resource "azurerm_data_factory_dataset_delimited_text" "adf_ds_delimited_text_01" {
  name                = "adfdsdelimitedtextlink01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_web.adf_link_service_web.name

  http_server_location {
    relative_url = "http://www.google.com"
    path         = "foo/bar/"
    filename     = "fizz.txt"
  }

  column_delimiter    = ","
  row_delimiter       = "NEW"
  encoding            = "UTF-8"
  quote_character     = "x"
  escape_character    = "f"
  first_row_as_header = true
  null_value          = "NULL"
}

##### HTTP #####
resource "azurerm_data_factory_dataset_http" "adf_ds_http_01" {
  name                = "adfdshttp01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_web.adf_link_service_web.name   # Uses linked service web (same as CSV)

  relative_url   = "http://www.google.com"
  request_body   = "foo=bar"
  request_method = "POST"
}

##### JSON #####
resource "azurerm_data_factory_dataset_json" "adf_ds_json_01" {
  name                = "adfdsjson01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_web.adf_link_service_web.name

  http_server_location {
    relative_url = "/fizz/buzz/"
    path         = "foo/bar/"
    filename     = "foo.txt"
  }

  encoding = "UTF-8"
}

/*
##### Parquet #####
resource "azurerm_data_factory_dataset_parquet" "adf_ds_parquet_01" {
  name                = "adfdsparquet01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_web.adf_link_service_web.name

  http_server_location {
    relative_url = "http://www.google.com"
    path         = "foo/bar/"
    filename     = "fizz.txt"
  }
}
*/

##### Linked Service for Table/SQL Server Storage #####
resource "azurerm_data_factory_linked_service_sql_server" "adf_link_sql_server" {
  name                = "adflinksqlserver"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  connection_string   = "Integrated Security=False;Data Source=test;Initial Catalog=test;User ID=test;Password=test"
}

##### Table/SQL Server Storage #####
resource "azurerm_data_factory_dataset_sql_server_table" "adf_ds_sql_server_01" {
  name                = "adfdssqlserver01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  linked_service_name = azurerm_data_factory_linked_service_sql_server.adf_link_sql_server.name
}

##### Linked Service for Azure File Storage #####
resource "azurerm_data_factory_linked_service_azure_file_storage" "adf_link_azure_file_storage" {
  name                = "adflinkazurefilestorage"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  # connection_string   = data.azurerm_storage_account.adf_storage.primary_connection_string
  connection_string   = azurerm_storage_account.adf_storage.primary_connection_string
}

/*
##### Data for Cosmos DB Storage #####
data "azurerm_cosmosdb_account" "adf_data_cosmosdb_account" {
  name                = "tfex-cosmosdb-account"
  resource_group_name = "tfex-cosmosdb-account-rg"
}

##### Linked Service for Cosmos DB Storage #####
resource "azurerm_data_factory_linked_service_cosmosdb" "adf_link_cosmosdb" {
  name                = "adflinkcosmosdb"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  account_endpoint    = azurerm_cosmosdb_account.adf_data_cosmosdb_account.endpoint
  account_key         = azurerm_cosmosdb_account.adf_data_cosmosdb_account.primary_access_key
  database            = "foo"
}
*/

/*
##### Data for Function App #####
data "azurerm_function_app" "adf_data_function_app" {
  name                = "test-azure-functions"
  resource_group_name = var.resource-group-dev
}

##### Linked Service for Azure Function #####
resource "azurerm_data_factory_linked_service_azure_function" "adf_link_azure_function" {
  name                = "adflinkazurefunction"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  url                 = "https://${data.azurerm_function_app.adf_data_function_app.default_hostname}"
  key                 = "foo"
}
*/

##### Linked Service for Synapse #####
resource "azurerm_data_factory_linked_service_synapse" "adf_link_synapse" {
  name                = "adflinksynapse"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name

  connection_string = "Integrated Security=False;Data Source=test;Initial Catalog=test;User ID=test;Password=test"
}

##### Data for Client Config of Data Lake Storage Gen2, Keyvault#####
data "azurerm_client_config" "current" {
}

##### Linked Service for Data Lake Storage Gen2 #####
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf_link_data_lake_storage_gen2" {
  name                  = "adflinkdatalakestoragegen2"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  service_principal_id  = data.azurerm_client_config.current.client_id
  service_principal_key = "exampleKey"
  tenant                = "11111111-1111-1111-1111-111111111111"
  url                   = "https://datalakestoragegen2"
}

################################ SQL Server ################################

/*
################################ Key Vault ################################
resource "azurerm_key_vault" "vault" {
  name = "${var.resource_prefix}sbxarmkeyuw2${var.resource_instance}"
  resource_group_name = var.resource-group-dev
  location = var.resource-location
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "restore",
      "purge",
      "recover"
    ]

    secret_permissions = [
      "list",
      "set",
      "get",
      "delete",
      "purge",
      "recover",
      "backup",
      "restore"
    ]
  }

  #Access policy for AD Group RG-ARM-ANALYTICS-DE-CONTRIBUTOR: 
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "2e5c5df3-18ab-46d9-8b68-5e8de931a8ff"

    key_permissions = [
      "create",
      "get",
      "list",
      "update",
      "create",
      "import",
      "delete",
      "restore",
      "purge",
      "recover"
    ]

    secret_permissions = [
      "list",
      "set",
      "get",
      "delete",
      "purge",
      "recover",
      "backup",
      "restore"
    ]
  }

  tags = var.common_tags
}

resource "azurerm_key_vault_secret" "secret" {
  name = "${azurerm_storage_account.adf_storage.name}-key"
  value = azurerm_storage_account.adf_storage.primary_access_key
  key_vault_id = azurerm_key_vault.vault.id
}

#Get SAS token
data "azurerm_storage_account_sas" "storage_sas_token" {
  connection_string = azurerm_storage_account.adf_storage.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = var.sas_start
  expiry = var.sas_expire

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
  }
}

#Store storage SAS token to key vault
resource "azurerm_key_vault_secret" "token" {
  name = "${azurerm_storage_account.adf_storage.name}-token"
  value = data.azurerm_storage_account_sas.storage_sas_token.sas
  key_vault_id = azurerm_key_vault.vault.id
  expiration_date = "${var.sas_expire}T23:59:59Z"
}

##### Linked Service for Key Vault #####
resource "azurerm_data_factory_linked_service_key_vault" "adf_link_key_vault" {
  name                = "adflinkkeyvault"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  key_vault_id        = azurerm_key_vault.vault.id
}
*/

/*
################################ Databricks ################################
# create pub subnet for databricks hosts
resource "azurerm_subnet" "pub_subnet" {
  name                 = "${var.resource_prefix}sbxarmsubuw2001"
  virtual_network_name = azurerm_virtual_network.injected_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["172.17.0.0/26"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action","Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action","Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

# create private subnet for databrics container
resource "azurerm_subnet" "pri_subnet" {
  name                 = "${var.resource_prefix}sbxarmsubuw2002"
  virtual_network_name = azurerm_virtual_network.injected_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["172.17.0.64/26"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation  {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action","Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action","Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_databricks_workspace" "databricks" {
  name = "${var.resource_prefix}sbxarmadbuw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  sku = "standard"
  managed_resource_group_name="databricks-rg-${var.resource_prefix}sbxarmadbuw2${var.resource_instance}"

  custom_parameters {
    no_public_ip = true
    public_subnet_name = azurerm_subnet.pub_subnet.name
    private_subnet_name = azurerm_subnet.pri_subnet.name
    virtual_network_id = azurerm_virtual_network.injected_vnet.id
  }
  tags = var.common_tags
}
*/

/*
################################ Azure Machine Learning ################################
resource "azurerm_resource_group" "rg" {
  name = "${var.resource_prefix}sbxarmrgp${var.resource_instance}"
  location = var.region

  tags = var.common_tags
}

# Create VNet
resource "azurerm_virtual_network" "injected_vnet" {
  name = "${var.resource_prefix}sbxarmvntuw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  address_space       = ["172.17.0.0/23"]
  tags = var.common_tags
}

# create  subnet machine learning worksplace compute
resource "azurerm_subnet" "aml_subnet" {
  name                 = "${var.resource_prefix}sbxarmsubuw2003"
  virtual_network_name = azurerm_virtual_network.injected_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["172.17.0.128/26"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_machine_learning_workspace" "aml" {
  name = "${var.resource_prefix}sbxarmmlwuw2${var.resource_instance}"
  location = var.region
  resource_group_name = azurerm_resource_group.rg.name
  key_vault_id = azurerm_key_vault.vault.id
  storage_account_id = azurerm_storage_account.storage.id
  application_insights_id = azurerm_application_insights.insights.id
  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags
}
*/
################################ Pipeline with JSON ################################
resource "azurerm_data_factory_pipeline" "adf_pipeline_01" {
  name                = "adfpipeline01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name

activities_json = <<JSON
[
  {
    "name": "Copy data1",
    "type": "Copy",
    "dependsOn": [],
    "policy": {
        "timeout": "7.00:00:00",
        "retry": 0,
        "retryIntervalInSeconds": 30,
        "secureOutput": false,
        "secureInput": false
    },
    "userProperties": [],
    "typeProperties": {
        "enableStaging": false
    }
  },
  {
      "name": "Notebook1",
      "type": "DatabricksNotebook",
      "dependsOn": [],
      "policy": {
          "timeout": "7.00:00:00",
          "retry": 0,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
      },
      "userProperties": []
  }
]
JSON
}

###### Trigger Schedule #####
resource "azurerm_data_factory_trigger_schedule" "adf_trigger_schedule" {
  name                = "adftriggerschedule"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name
  pipeline_name       = azurerm_data_factory_pipeline.adf_pipeline_01.name

  interval  = 5
  frequency = "Day"
}

/*
################################ ADF Dataflow ################################
resource "azurerm_data_factory_dataflow" "adf_data_flow_01" {
  name                = "adfdataflow01"
  resource_group_name = var.resource-group-dev
  data_factory_name   = azurerm_data_factory.adf_test.name

activities_json = <<JSON
[
  {
    "name": "dataflow1",
    "properties": {
        "type": "MappingDataFlow",
        "typeProperties": {
            "sources": [],
            "sinks": [],
            "transformations": [],
            "script": ""
        }
    }
  }
]
JSON
}
*/
