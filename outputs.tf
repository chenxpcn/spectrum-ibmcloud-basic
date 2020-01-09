output "master_public_ip_address" {
  value = "${ibm_compute_vm_instance.master-host.ipv4_address}"
}

output "master_private_ip_address" {
  value = "${ibm_compute_vm_instance.master-host.ipv4_address_private}"
}

output "compute_public_ip_address" {
  value = "${ibm_compute_vm_instance.compute-host.ipv4_address}"
}

output "compute_private_ip_address" {
  value = "${ibm_compute_vm_instance.compute-host.ipv4_address_private}"
}
