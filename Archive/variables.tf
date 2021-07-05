/*
variable "region" { 
    default = "westus2"
}

# variable "container_name" { }

variable "resource_prefix" { }

variable "resource_instance" { }

# variable "databrickssubnet1number" { }
# variable "databrickssubnet2number" { }
# variable "databrickssubnet1ip" { }
# variable "databrickssubnet2ip" { }


variable "sas_start" {
  description = "SAS token start date"
  default = "2021-03-10"
}

variable "sas_expire" {
  description = "SAS token expire date"
  default = "2028-03-10"
}


#common cost and tracking tags
variable "common_tags" {
  description   = "Map of common suncor tags to apply to The resource group"
  type          = map(string)

  default = {
    BillingIndicator = "C1601169"
    ConsumerOrganization1 = "Corporate"
    ConsumerOrganization2 = "TMO"
    EnvironmentType = "SBX"
    ITCoreService = ""
    SuncorKeyIDApplicationName = "SUN0003400[Azure Advanced Analytics Platform]"
    SupportStatus = "ABO"
    Initiative = ""
    Notes = ""
  }
}
*/