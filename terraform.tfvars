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

# (required) data center where master host and compute host will be provisioned
# data_center = "dal13"
data_center = ""

# (optional) public vlan id for master host
# public_vlan_id = "2317207"

# (optional) private vlan id for both master host and compute host
# private_vlan_id = "2317209"

# (optional) private vlan number for both master host and compute host
# private_vlan_number = "1207"

# (optional) cpu cores for master host
# master_cores = "4"

# (optional) memory in MBytes on master host
# master_memory = "32768"

# (optional) network speed in Mbps on master host
# master_network_speed = "100"

# (optional) cpu cores for compute host
# compute_cores = "2"

# (optional) memory in MBytes on compute host
# compute_memory = "4096"

# (optional) network speed in Mbps on compute host
# compute_network_speed = "100"

# (optional) image name for dynamic host, the image is come from compute host
# image_name = "SpectrumClusterDynamicHostImage"

# (required) the content of entitlement file, use '\n' to separate lines
# entitlement = "LSF_Suite_for_Enterprise   10.1   ()   ()   ()   ()   0123456789abcdef"
# entitlement = "ego_base   3.8   30/11/2020   ()   ()   ()   0123456789abcdef\nsym_advanced_edition   7.3   30/11/2020   ()   ()   ()   fedcba9876543210"
