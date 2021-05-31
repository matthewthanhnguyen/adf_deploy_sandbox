provider "azurerm" {
  version = ">= 2.49.0"
  features {}
subscription_id = "b54182d2-60c0-4e34-b1ab-499a3394771d"
use_msi = true
}


terraform {
    backend "azurerm" {
        resource_group_name     = "iww_sandbox"
        storage_account_name    = "opstf"
        container_name          = "tfstatedevops"
        # key                     = "sbx/terraform.tfstate"
    }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name = "${var.resource_prefix}sbxarmrgp${var.resource_instance}"
  location = var.region

  tags = var.common_tags
}

resource "azurerm_storage_account" "storage" {
  name = "${var.resource_prefix}sbxarmstauw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  min_tls_version = "TLS1_2"
  account_tier = "Standard"
  account_replication_type = "LRS"
  network_rules {
    default_action = "Deny"
    bypass = [
      "AzureServices"
    ]
    ip_rules                   = ["209.82.26.128/25","156.44.138.0/23","156.44.152.0/23","156.44.154.0/23","156.44.128.0/23"]  # Suncor Calgary IP  address
    virtual_network_subnet_ids = [azurerm_subnet.pub_subnet.id,azurerm_subnet.pri_subnet.id,azurerm_subnet.aml_subnet.id]
  }
  tags = var.common_tags
}

# resource "azurerm_storage_container" "container" {
#   name = var.container_name
#   storage_account_name  = azurerm_storage_account.storage.name
#   container_access_type = "private"
# }

resource "azurerm_key_vault" "vault" {
  name = "${var.resource_prefix}sbxarmkeyuw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
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
  name = "${azurerm_storage_account.storage.name}-key"
  value = azurerm_storage_account.storage.primary_access_key
  key_vault_id = azurerm_key_vault.vault.id
}


#Get SAS token
data "azurerm_storage_account_sas" "storage_sas_token" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
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
  name = "${azurerm_storage_account.storage.name}-token"
  value = data.azurerm_storage_account_sas.storage_sas_token.sas
  key_vault_id = azurerm_key_vault.vault.id
  expiration_date = "${var.sas_expire}T23:59:59Z"
}

# Section for vnet injection of databricks
# # Bring in VNet RG
# data "azurerm_resource_group" "resource_group_vnet" {
#   name = "aaasbxarmrgp000"
# }

# # bring in existing vnet for databrick vnet injection
# data "azurerm_virtual_network" "injected_vnet" {
#   name = "aaasbxarmvntuw2100"
#   resource_group_name = data.azurerm_resource_group.resource_group_vnet.name
# }


# # Bring in nsg
# data "azurerm_network_security_group" "nsg" {
#   name                = "aaasbxarmnsguw2100"
#   resource_group_name = data.azurerm_resource_group.resource_group_vnet.name
# }

# Create VNet
resource "azurerm_virtual_network" "injected_vnet" {
  name = "${var.resource_prefix}sbxarmvntuw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  address_space       = ["172.17.0.0/23"]
  tags = var.common_tags
}

# Create nsg
resource "azurerm_network_security_group" "nsg" {
  name = "${var.resource_prefix}sbxarmnsguw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  tags = var.common_tags
}



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

# pub subnet associateion with nsg
resource "azurerm_subnet_network_security_group_association" "pub_nsg" {
  subnet_id                 = azurerm_subnet.pub_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
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

# private subnet association with nsg
resource "azurerm_subnet_network_security_group_association" "pri_nsg" {
  subnet_id                 = azurerm_subnet.pri_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# create  subnet machine learning worksplace compute
resource "azurerm_subnet" "aml_subnet" {
  name                 = "${var.resource_prefix}sbxarmsubuw2003"
  virtual_network_name = azurerm_virtual_network.injected_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["172.17.0.128/26"]
  service_endpoints    = ["Microsoft.Storage"]
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



resource "azurerm_application_insights" "insights" {
  name = "${var.resource_prefix}sbxarmaaiuw2${var.resource_instance}"
  location = var.region
  resource_group_name = azurerm_resource_group.rg.name
  application_type = "web"

  tags = var.common_tags
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

#Generate random password for SQL server

resource "random_password" "sql_server_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_mssql_server" "sql" {
  name = "${var.resource_prefix}sbxarmsvruw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  version = "12.0"
  administrator_login = "am${var.resource_prefix}sbxarmsvruw2${var.resource_instance}"
  administrator_login_password = random_password.sql_server_password.result
  minimum_tls_version = "1.2"

  azuread_administrator {
    login_username = "RG-ARM-ABO-SQL-ADMIN"
    object_id      = "9ca20e88-4949-4ad3-851f-e47c581e5213"
  }

  tags = var.common_tags
}

# Setup firewall to allow Suncor Calgary connections

resource "azurerm_sql_firewall_rule" "sql_firewall_suncor_cgy1" {
  name                = "Suncor_CGY1"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql.name
  start_ip_address    = "209.82.26.129"
  end_ip_address      = "209.82.26.254"
}


resource "azurerm_sql_firewall_rule" "sql_firewall_suncor_cgy2" {
  name                = "Suncor_CGY2"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql.name
  start_ip_address    = "156.44.138.1"
  end_ip_address      = "156.44.139.254"
}

resource "azurerm_sql_firewall_rule" "sql_firewall_suncor_cgy3" {
  name                = "Suncor_CGY3"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql.name
  start_ip_address    = "156.44.152.1"
  end_ip_address      = "156.44.153.254"
}

resource "azurerm_sql_firewall_rule" "sql_firewall_suncor_cgy4" {
  name                = "Suncor_CGY4"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql.name
  start_ip_address    = "156.44.154.1"
  end_ip_address      = "156.44.155.254"
}

resource "azurerm_sql_firewall_rule" "sql_firewall_suncor_cgy5" {
  name                = "Suncor_CGY5"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql.name
  start_ip_address    = "156.44.128.1"
  end_ip_address      = "156.44.129.254"
}



# Setup firewall to allow Microsoft services

resource "azurerm_sql_firewall_rule" "sql_firewall_azure" {
  name                = "Azure_Services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}


#Store SQL admin username to key vault
resource "azurerm_key_vault_secret" "sql_username" {
  name = "sql-admin-username"
  value = "am${azurerm_mssql_server.sql.name}"
  key_vault_id = azurerm_key_vault.vault.id
}


#Store SQL admin password to key vault
resource "azurerm_key_vault_secret" "sql_pw" {
  name = "sql-admin-password"
  value = random_password.sql_server_password.result
  key_vault_id = azurerm_key_vault.vault.id
}


resource "azurerm_data_factory" "adf" {
  name = "${var.resource_prefix}sbxarmadfuw2${var.resource_instance}"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.region
  identity {
    type = "SystemAssigned"
  }
  tags = var.common_tags
}

# Assign ADF's managed identity to the storage account as Data Contributor
resource "azurerm_role_assignment" "adf_access_storage" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}


# Add Storage account to data factory
resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf_link_to_storage" {
  name                = azurerm_storage_account.storage.name
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.adf.name
  connection_string   = azurerm_storage_account.storage.primary_connection_string
  use_managed_identity = true

}



resource "azurerm_role_assignment" "rbac" {
  scope = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id = "2e5c5df3-18ab-46d9-8b68-5e8de931a8ff"   # RG-ARM-ANALYTICS-DE-CONTRIBUTOR
}