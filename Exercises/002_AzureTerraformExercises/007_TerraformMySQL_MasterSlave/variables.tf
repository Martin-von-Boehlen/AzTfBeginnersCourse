# Loop:
# resource "aws_iam_user" "example" {
#   count = 3
#   name  = "neo.${count.index}"
# }

variable "location_spread" {
    default = [ "westeurope", "northeurope"]
}

variable "account_location" {
  default = "westeurope"
}

variable "resource_group_name" {
  default = "maria-resources"
}

variable "maria_host_pre" {
  default = "mvb4712-maria"
}

variable "maria_fqdn_post" {
  default = ".westeurope.cloudapp.azure.com"
}

variable "maria_srv_count" {
  default = 2
}


variable "maria_usr_name" {
  default = "sqladmin"
}

variable "maria_usr_pwd" {
  default = "blackmaria"
}

variable "maria_rep_name" {
  default = "repl"
}

variable "maria_rep_pwd" {
  default = "Hallabalu1806!"
}

