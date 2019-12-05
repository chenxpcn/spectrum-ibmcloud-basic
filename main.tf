locals {
  MASTER_HOST = "master-host"
  COMPUTE_HOST = "compute-host"
  DEFAULT_SCRIPTS_URI = "https://raw.githubusercontent.com/chenxpcn/spectrum-ibmcloud-basic/master/scripts"
  product_name = "${var.spectrum_product == "symphony" ? "symphony" : "lsf"}"
  scripts_uri = "${var.scripts_path_uri == "" ? local.DEFAULT_SCRIPTS_URI : var.scripts_path_uri}"
  deployer_ssh_key_file_name = "deployer-ssh-key"
  master_ssh_key_file_name = "spectrum-master-ssh-key"
  compute_ssh_key_file_name = "spectrum-compute-ssh-key"
  param_list = [
                "${local.scripts_uri}",
                "${var.installer_uri}",
                "${var.entitlement_uri}",
                "${base64encode(var.cluster_admin_password)}",
                "${base64encode(var.remote_console_public_ssh_key)}",
                "${ibm_compute_vm_instance.master-host.hostname}.${ibm_compute_vm_instance.master-host.domain}",
                "${ibm_compute_vm_instance.master-host.ipv4_address_private}", 
                "${ibm_compute_vm_instance.compute-host.hostname}.${ibm_compute_vm_instance.compute-host.domain}",
                "${ibm_compute_vm_instance.compute-host.ipv4_address_private}", 
                "${ibm_compute_vm_instance.compute-host.id}", 
                "${var.cluster_name}",
                "${base64encode(var.ibmcloud_iaas_classic_username)}",
                "${base64encode(var.ibmcloud_iaas_api_key)}",
                "${var.data_center}", 
                "${var.private_vlan_id}", 
                "${var.compute_cores}", 
                "${var.compute_memory}", 
                "${base64encode(var.image_name)}", 
                "${var.private_vlan_number}", 
                ]
  parameters = "${join(" ", local.param_list)}"
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

resource "null_resource" "create_master_ssh_key" {
  provisioner "local-exec" {
    command = "if [ ! -f '${local.master_ssh_key_file_name}' ]; then ssh-keygen -f ${local.master_ssh_key_file_name} -N '' -C 'master@master'; fi"
  }
}

resource "null_resource" "create_compute_ssh_key" {
  provisioner "local-exec" {
    command = "if [ ! -f '${local.compute_ssh_key_file_name}' ]; then ssh-keygen -f ${local.compute_ssh_key_file_name} -N '' -C 'compute@compute'; fi"
  }
}

resource "ibm_compute_vm_instance" "master-host" {
  hostname             = "${local.MASTER_HOST}"
  domain               = "${var.domain_name}"
  os_reference_code    = "REDHAT_7_64"
  datacenter           = "${var.data_center}"
  network_speed        = "${var.master_network_speed}"
  hourly_billing       = true
  private_network_only = false
  cores                = "${var.master_cores}"
  memory               = "${var.master_memory}"
  disks                = ["${var.master_disk}"]
  local_disk           = false
  public_vlan_id       = "${var.public_vlan_id}"
  private_vlan_id      = "${var.private_vlan_id}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.deployer_ssh_key.id}"]
  depends_on           = ["ibm_compute_ssh_key.deployer_ssh_key"]
}

resource "ibm_compute_vm_instance" "compute-host" {
  hostname             = "${local.COMPUTE_HOST}"
  domain               = "${var.domain_name}"
  os_reference_code    = "REDHAT_7_64"
  datacenter           = "${var.data_center}"
  network_speed        = "${var.compute_network_speed}"
  hourly_billing       = true
  private_network_only = false
  cores                = "${var.compute_cores}"
  memory               = "${var.compute_memory}"
  disks                = ["${var.compute_disk}"]
  local_disk           = false
  public_vlan_id       = "${var.public_vlan_id}"
  private_vlan_id      = "${var.private_vlan_id}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.deployer_ssh_key.id}"]
  depends_on           = ["ibm_compute_ssh_key.deployer_ssh_key"]
}

resource "null_resource" "pre-install-master" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.master-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "file" {
    source      = "${local.master_ssh_key_file_name}"
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "${local.master_ssh_key_file_name}.pub"
    destination = "/root/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = "${local.compute_ssh_key_file_name}.pub"
    destination = "/root/.ssh/compute-host.pub"
  }

  provisioner "remote-exec" {
    inline  = [
      "mkdir -p /root/installer",
      "mkdir -p /root/logs",
      "wget -nv -nH -c --no-check-certificate -O /root/installer/downloads.sh ${local.scripts_uri}/${local.product_name}/downloads.sh",
      ". /root/installer/downloads.sh master ${local.parameters}",
      ". /root/installer/pre-install.sh master ${local.parameters}",
    ]
  }

  depends_on = ["null_resource.create_master_ssh_key","null_resource.create_compute_ssh_key","ibm_compute_vm_instance.master-host"]
}

resource "null_resource" "pre-install-compute" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.compute-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "file" {
    source      = "${local.compute_ssh_key_file_name}"
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "${local.compute_ssh_key_file_name}.pub"
    destination = "/root/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = "${local.master_ssh_key_file_name}.pub"
    destination = "/root/.ssh/master-host.pub"
  }

  provisioner "remote-exec" {
    inline  = [
      "mkdir -p /root/installer",
      "mkdir -p /root/logs",
      "wget -nv -nH -c --no-check-certificate -O /root/installer/downloads.sh ${local.scripts_uri}/${local.product_name}/downloads.sh",
      ". /root/installer/downloads.sh compute ${local.parameters}",
      ". /root/installer/pre-install.sh compute ${local.parameters}",
    ]
  }

  depends_on = ["null_resource.create_master_ssh_key","null_resource.create_compute_ssh_key","ibm_compute_vm_instance.master-host","ibm_compute_vm_instance.compute-host"]
}

resource "null_resource" "install-master" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.master-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "remote-exec" {
    inline  = [
      ". /root/installer/install.sh master ${local.parameters}",
    ]
  }

  depends_on = ["null_resource.pre-install-master","null_resource.pre-install-compute"]
}

resource "null_resource" "install-compute" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.compute-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "remote-exec" {
    inline  = [
      ". /root/installer/install.sh compute ${local.parameters}",
    ]
  }

  depends_on = ["null_resource.install-master"]
}

resource "null_resource" "post-install-master" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.master-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "remote-exec" {
    inline  = [
      ". /root/installer/post-install.sh master ${local.parameters}",
      ". /root/installer/clean.sh master",
    ]
  }

  provisioner "local-exec" {
    command = "rm -f ${local.master_ssh_key_file_name} ${local.master_ssh_key_file_name}.pub"
  }

  depends_on = ["null_resource.install-master","null_resource.install-compute"]
}

resource "null_resource" "post-install-compute" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${ibm_compute_vm_instance.compute-host.ipv4_address}"
    private_key = "${data.local_file.deployer_ssh_private_key.content}"
  }

  provisioner "remote-exec" {
    inline  = [
      ". /root/installer/post-install.sh compute ${local.parameters}",
      ". /root/installer/clean.sh compute",
    ]
  }

  provisioner "local-exec" {
    command = "rm -f ${local.compute_ssh_key_file_name} ${local.compute_ssh_key_file_name}.pub"
  }

  depends_on = ["null_resource.post-install-master"]
}

