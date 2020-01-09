# variables supplied from terraform.tfvars

############################################################
# for provider.tf
variable "ibmcloud_iaas_classic_username" {
  type = "string"
  description = "softlayer user name"
}

variable "ibmcloud_iaas_api_key" {
  type = "string"
  description = "softlayer api key"
}

variable "ibmcloud_api_key" {
  type = "string"
  description = "ibmcloud api key"
}

############################################################
# for main.tf
variable "spectrum_product" {
  type = "string"
  description = "symphony or lsf"
  default = "symphony"
}

variable "data_center" {
  type = "string"
  description = "Data Center"
}

variable "public_vlan_id" {
  type = "string"
  description = "Public VLAN ID for master host"
  default = "0"
}

variable "private_vlan_id" {
  type = "string"
  description = "Private VLAN ID for both master host and compute host"
  default = "0"
}

variable "private_vlan_number" {
  type = "string"
  description = "Private VLAN number for both master host and compute host"
  default = "0"
}

variable "master_cores" {
  type = "string"
  description = "CPU cores on master host"
  default = "4"
}

variable "master_memory" {
  type = "string"
  description = "Memory in MBytes on master host"
  default = "32768"
}

variable "master_network_speed" {
  type = "string"
  description = "Network speed in Mbps on master host"
  default = "100"
}

variable "compute_cores" {
  type = "string"
  description = "CPU cores on compute host"
  default = "2"
}

variable "compute_memory" {
  type = "string"
  description = "Memory in MBytes on compute host"
  default = "4096"
}

variable "compute_network_speed" {
  type = "string"
  description = "Network speed in Mbps on compute host"
  default = "100"
}

variable "remote_console_public_ssh_key" {
  type = "string"
  description = "Public SSH key of remote console for control"
}

variable "image_name" {
  type = "string"
  description = "Image name for dynamic compute host"
  default = "SpectrumClusterDynamicHostImage"
}

variable "entitlement" {
  type = "string"
  description = "Content of entitlement file, if there are multiple lines in the file, separate lines with `\n`.  For example, `ego_base   3.8   30/11/2020   ()   ()   ()   0123456789abcdef\nsym_advanced_edition   7.3   30/11/2020   ()   ()   ()   fedcba9876543210`"
}
