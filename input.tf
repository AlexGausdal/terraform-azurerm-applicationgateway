variable "k8s_name" {
    type        = string
    description = "AKS cluster name."
}

variable "rg_k8s_name" {
    type        = string
    description = "AKS resource group name."
}

variable "virtual_network_name" {
    type        = string
    description = "AKS virtual network name."
}

variable "k8s_agw_snet_address_prefixes" {
    description = "AGW subnets."
}

variable "location" {
    type        = string
    description = "Location."
}

variable "tags" {
    description = "Tags."
}