variable "resource-group-dev" {
  description = "azurerm resource groups"
  default     = "adf_example_dev"
}

variable "resource-location" {
  description = "The location to deploy instances in"
  default     = "Canada Central"
}

variable "subscription-id" {
  default     = "b54182d2-60c0-4e34-b1ab-499a3394771d"
}

variable "resource_prefix" {
  default     = "suncor"
}

variable "resource_instance" {
  default     = "suncor"
}

variable "region" { 
    default = "westus2"
}

variable "github-account-name" { 
    default = "hagan3"
}

variable "github-branch-name" { 
    default = "main"
}

variable "github-git-url" { 
    default = "https://github.com"
}

variable "github-repository-name" { 
    default = "adf_deploy_sandbox"
}

variable "github-root-folder" { 
    default = "/"
}

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
