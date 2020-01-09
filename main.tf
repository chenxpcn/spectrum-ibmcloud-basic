locals {
  MASTER_HOST = "master-host"
  COMPUTE_HOST = "compute-host-1"
  product_name = "${var.spectrum_product == "symphony" ? "symphony" : "lsf"}"
  domain_name = "${var.spectrum_product == "symphony" ? "symphony.spectrum" : "lsf.spectrum"}"
  cluster_name = "${var.spectrum_product == "symphony" ? "symphony-cluster-simple" : "lsf-cluster-simple"}"
  preinstalled_master_image_name = "${var.spectrum_product == "symphony" ? "Spectrum_Symphony_Simple_Master" : "Spectrum_LSF_Simple_Master"}"
  preinstalled_compute_image_name = "${var.spectrum_product == "symphony" ? "Spectrum_Symphony_Simple_Compute" : "Spectrum_LSF_Simple_Compute"}"
  deployer_ssh_key_file_name = "deployer-ssh-key"
  config_master_param_list = [
    "${ibm_compute_vm_instance.master-host.ipv4_address_private}",
    "${ibm_compute_vm_instance.compute-host.hostname}.${ibm_compute_vm_instance.compute-host.domain}",
    "${ibm_compute_vm_instance.compute-host.ipv4_address_private}",
    "${base64encode(var.entitlement)}",
    "${base64encode(var.image_name)}",
    "${base64encode(var.ibmcloud_iaas_classic_username)}",
    "${base64encode(var.ibmcloud_iaas_api_key)}",
    "${ibm_compute_vm_instance.compute-host.id}",
    "${base64encode(var.remote_console_public_ssh_key)}",
    "${var.data_center}",
    "${var.private_vlan_number}",
    "${var.private_vlan_id}",
    "${local.cluster_name}",
  ]
  config_master_param = "${join(" ", local.config_master_param_list)}"
}

resource "null_resource" "create_deployer_ssh_key" {
  provisioner "local-exec" {
    command = "if [ ! -f '${local.deployer_ssh_key_file_name}' ]; then ssh-keygen -f ${local.deployer_ssh_key_file_name} -N '' -C 'deployer@deployer'; fi"
  }
}

data "local_file" "deployer_ssh_public_key" {
  filename = "${local.deployer_ssh_key_file_name}.pub"
  depends_on = ["null_resource.create_deployer_ssh_key"]
}

data "local_file" "deployer_ssh_private_key" {
  filename = "${local.deployer_ssh_key_file_name}"
  depends_on = ["null_resource.create_deployer_ssh_key"]
}

resource "ibm_compute_ssh_key" "deployer_ssh_key" {
  label      = "deployer_ssh_key"
  public_key = "${data.local_file.deployer_ssh_public_key.content}"
  depends_on = ["null_resource.create_deployer_ssh_key"]
}

data "ibm_compute_image_template" "master_image" {
    name = "${local.preinstalled_master_image_name}"
}

data "ibm_compute_image_template" "compute_image" {
    name = "${local.preinstalled_compute_image_name}"
}

resource "ibm_compute_vm_instance" "master-host" {
  hostname             = "${local.MASTER_HOST}"
  domain               = "${local.domain_name}"
  image_id             = "${data.ibm_compute_image_template.master_image.id}"
  datacenter           = "${var.data_center}"
  network_speed        = "${var.master_network_speed}"
  hourly_billing       = true
  private_network_only = false
  cores                = "${var.master_cores}"
  memory               = "${var.master_memory}"
  local_disk           = false
  public_vlan_id       = "${var.public_vlan_id}"
  private_vlan_id      = "${var.private_vlan_id}"
  public_vlan_id       = "0"
  private_vlan_id      = "0"
  ssh_key_ids          = ["${ibm_compute_ssh_key.deployer_ssh_key.id}"]
  depends_on           = ["ibm_compute_ssh_key.deployer_ssh_key"]
}

resource "ibm_compute_vm_instance" "compute-host" {
  hostname             = "${local.COMPUTE_HOST}"
  domain               = "${local.domain_name}"
  image_id             = "${data.ibm_compute_image_template.compute_image.id}"
  datacenter           = "${var.data_center}"
  network_speed        = "${var.compute_network_speed}"
  hourly_billing       = true
  private_network_only = false
  cores                = "${var.compute_cores}"
  memory               = "${var.compute_memory}"
  local_disk           = false
  public_vlan_id       = "${var.public_vlan_id}"
  private_vlan_id      = "${var.private_vlan_id}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.deployer_ssh_key.id}"]
  depends_on           = ["ibm_compute_ssh_key.deployer_ssh_key"]
}

resource "null_resource" "config-master" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.master-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "remote-exec" {
    inline  = [
      ". /root/installer/config-master.sh ${local.config_master_param}",
      ". /root/installer/clean.sh",
    ]
  }

  depends_on = ["ibm_compute_vm_instance.master-host","ibm_compute_vm_instance.compute-host"]
}

resource "null_resource" "config-compute" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.compute-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "remote-exec" {
    inline  = [
      ". /root/installer/config-compute.sh ${ibm_compute_vm_instance.master-host.hostname}.${ibm_compute_vm_instance.master-host.domain} ${ibm_compute_vm_instance.master-host.ipv4_address_private} ${ibm_compute_vm_instance.compute-host.hostname}.${ibm_compute_vm_instance.compute-host.domain}", 
      ". /root/installer/clean.sh",
    ]
  }

  depends_on = ["null_resource.config-master"]
}
