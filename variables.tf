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

variable "cluster_name" {
  type = "string"
  description = "Symphony / LSF cluster name"
  default = "spectrum-cluster"
}

variable "domain_name" {
  type = "string"
  description = "Domain name"
  default = "spectrum.ibmcloud"
}

variable "data_center" {
  type = "string"
  description = "Data Center"
}

variable "public_vlan_id" {
  type = "string"
  description = "Public VLAN ID for master host"
}

variable "private_vlan_id" {
  type = "string"
  description = "Private VLAN ID for both master host and compute host"
}

variable "private_vlan_number" {
  type = "string"
  description = "Private VLAN number for both master host and compute host"
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

variable "master_disk" {
  type = "string"
  description = "Disk size in GBytes on master host"
  default = "100"
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

variable "compute_disk" {
  type = "string"
  description = "Disk size in GBytes on compute host"
  default = "25"
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

variable "scripts_path_uri" {
  type = "string"
  description = "URI of scripts folder"
  default = "https://raw.githubusercontent.com/chenxpcn/spectrum-ibmcloud-basic/master/scripts"
}

variable "installer_uri" {
  type = "string"
  description = "URI of Symphony / LSF installer package"
}

variable "entitlement_uri" {
  type = "string"
  description = "URI of Symphony entitlement file"
  default="n/a"
}

variable "cluster_admin_password" {
  type = "string"
  description = "Password for cluster administrator"
}

variable "image_name" {
  type = "string"
  description = "Image name for dynamic compute host"
  default = "SpectrumClusterDynamicHostImage"
}
