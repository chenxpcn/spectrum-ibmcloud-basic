# (required) your IBM IaaS Classic Infrastructure full username
ibmcloud_iaas_classic_username = ""

# (required) your IBM IaaS Classic Infrastructure API key
ibmcloud_iaas_api_key = ""

# (required) Enter your IBM Cloud API Key
ibmcloud_api_key = ""

# (required) public ssh key for remote console that used to control the master host
remote_console_public_ssh_key = ""

# (optional) Spectrum product need to be installed, either symphony or lsf
# spectrum_product = "symphony"

# (optional) Symphony / LSF cluster name
# cluster_name = "spectrum-cluster"

# (optional) uri of scripts folder
# scripts_path_uri = "https://raw.githubusercontent.com/chenxpcn/spectrum-lsf-ibmcloud/master/scripts"
scripts_path_uri = ""

# (required) uri of installer package
# installer_uri = "http://<http_server_ip>/suite/lsfsent10.2.0.8-x86_64.bin"
installer_uri = ""

# (required) uri of entitlement file
# entitlement_uri = "http://<http_server_ip>/entitlements/sym_adv_ev_entitlement.dat"
entitlement_uri = ""

# (required) password for cluster administrator
# cluster_admin_password = "spectrumpassw0rd"
cluster_admin_password = ""

# (optional) domain name for master host and compute host
# domain_name = "spectrum.ibmcloud"

# (required) data center where master host and compute host will be provisioned
# data_center = "dal13"
data_center = ""

# (required) public vlan id for master host
# public_vlan_id = "2317207"
public_vlan_id = ""

# (required) private vlan id for both master host and compute host
# private_vlan_id = "2317209"
private_vlan_id = ""

# (required) private vlan number for both master host and compute host
# private_vlan_number = "1207"
private_vlan_number = ""

# (optional) cpu cores for master host
# master_cores = "4"

# (optional) memory in MBytes on master host
# master_memory = "32768"

# (optional) disk size in GBytes on master host
# master_disk = "100"

# (optional) network speed in Mbps on master host
# master_network_speed = "100"

# (optional) cpu cores for compute host
# compute_cores = "2"

# (optional) memory in MBytes on compute host
# compute_memory = "4096"

# (optional) disk size in GBytes on compute host
# compute_disk = "25"

# (optional) network speed in Mbps on compute host
# compute_network_speed = "100"

# (optional) image name for dynamic host, the image is come from compute host
# image_name = "SpectrumClusterDynamicHostImage"
