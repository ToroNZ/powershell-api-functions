variable "location" {
  description = "Azure Location (aka region name)"
  type        = string
  default     = "australiaeast"
}

variable "rgname" {
  description = "Resource Group name"
  type        = string
  default     = "powershell-functions"
}

variable "storage_account_name" {
  type    = string
  default = "demoterraformtfstate"
}

variable "CLIENTID" {
  type = string
}
