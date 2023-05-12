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

variable "CLIENTID" {
  type = string
}

variable "PUBLIC_IP" {
  type = string
}

variable "frontend_code" {
  type    = string
  default = "../functions/frontend"
}
