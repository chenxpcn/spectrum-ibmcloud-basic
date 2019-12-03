provider "ibm" {
  version            = "~> 0.17"
  iaas_classic_username = "${var.ibmcloud_iaas_classic_username}"
  iaas_classic_api_key  = "${var.ibmcloud_iaas_api_key}"
  ibmcloud_api_key   = "${var.ibmcloud_api_key}"
}
