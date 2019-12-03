# IBM Spectrum LSF / Symphony Cluster on IBM Cloud Template

An [IBM Cloud Schematics](https://cloud.ibm.com/docs/schematics?topic=schematics-about-schematics) template to deploy and launch an HPC (High Performance Computing) cluster Tech Preview, IBM Spectrum LSF Suite (with Resource Connector) and IBM Spectrum Symphony (with HostFactory) is used in the Tech Preview.
Schematics uses [Terraform](https://www.terraform.io/) as the infrastructure as code engine. With this template, you can provision and manage infrastructure as a single unit.
See the [Terraform provider docs](https://ibm-cloud.github.io/tf-ibm-docs/) for available resources for the IBM Cloud. **Note**: To create the resources that this template requests, your [IBM Cloud Infrastructure (Softlayer) account](https://cloud.ibm.com/docs/iam?topic=iam-mngclassicinfra#managing-infrastructure-access) and [IBM Cloud account](https://cloud.ibm.com/docs/iam?topic=iam-iammanidaccser#iammanidaccser) must have sufficient permissions.

**IMPORTANT**

Due to legal requirement, we cannot provide product packages and entitlement in this template. 
For LSF, we use IBM Spectrum LSF Suite for Enterprise 10.2.0.8 (for Linux on x86-64 English), you should provide your own installation package, and specify the URL of the installation package in the variable `installer_uri` in the Variables section of your environment created using this template.  You maybe get IBM Spectrum LSF Suite for Enterprise 10.2.0.8 from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/index.html).
For Symphony, we use IBM Spectrum Symphony 7.3.0.0 Evaluation Edition for Linux (64-bit), you should provide the URL of installation package in the variable `installer_uri` and the URL of entitlement file in variable `entitlement_uri`.

## Brief Introduction
This template will deploy a HPC cluster with IBM Spectrum LSF or IBM Spectrum Symphony on IBM Cloud, the Resource Connector / Host Factory will be enabled automatically.
Since this is just a Tech Preview, the configuration for the HPC cluster includes one master node and one static compute node only, the compute node will be used to run jobs.  
Once the compute node can't cover the job load, the Resource Connector / Host Factory will request a new Virtual Server from IBM Cloud, then the Virtual Server will be added to the HPC cluster as a dynamic compute node.  After the dynamic compute node complete jobs and idled for a while, it will be removed for the cluster and deleted in the IBM Cloud automatically.

## Usage

### Create workspaces in IBM Cloud Schematics
1. Open [Schematics dashboard](https://cloud.ibm.com/schematics).
2. Click the button **Create a workspace**
3. Fill **Workspace name** with a name for the workspace 
4. Fill **GitHub or GitLab repository URL** with the URL of this template Git repository, say https://github.com/chenxpcn/spectrum-ibmcloud-basic
5. Click button **Retrieve input variables**, fill values for variables.  Refrence following table for the detail information about variables.
6. Click button **Create** at right side of the page.

To create a HPC cluster with this workspace 
1. Click button **Generate plan**, check **Recent activity** list, wait the generation action complete, either **Plan generated** for success or **Failed to generate plan** for failed, click **View log** for detail log.
2. Click button **Apply plan**, check **Recent activity** list, wait the apply action complete, either **Plan applied** for success or **Failed to apply plan** for failed, click **View log** for detail log.

### Create an environment with Terraform Binary on your local workstation
1. Install the Terraform, to apply this template, you need to install the latest update of Terraform v0.11 (**Do not install v0.12**), you can download Terraform v0.11 package from [here](https://releases.hashicorp.com/terraform/)
2. Install the IBM Cloud Provider Plugin
- [Download the IBM Cloud provider plugin for Terraform](https://github.com/IBM-Bluemix/terraform-provider-ibm/releases).

- Unzip the release archive to extract the plugin binary (`terraform-provider-ibm_vX.Y.Z`).

- Move the binary into the Terraform [plugins directory](https://www.terraform.io/docs/configuration/providers.html#third-party-plugins) for the platform.
    - Linux/Unix/OS X: `~/.terraform.d/plugins`
    - Windows: `%APPDATA%\terraform.d\plugins`

To run this project locally:

1. Set values for variables in `terraform.tfvars`
2. Switch to the project folder in terminal, run `terraform init`.  Terraform performs initialization on the local environment.
2. Run `terraform plan`. Terraform performs a dry run to show what resources will be created.
3. Run `terraform apply`. Terraform creates and deploys resources to your environment.
    * You can see deployed infrastructure in [IBM Cloud Console](https://cloud.ibm.com/classic/devices).
4. Run `terraform destroy`. Terraform destroys all deployed resources in this environment.

### Variables
|Variable Name|Description|Default Value|
|-------------|-----------|-------------|
|ibmcloud_iaas_classic_username|IBM Cloud Classic Infrastructure username||
|ibmcloud_iaas_api_key|IBM Cloud Classic Infrastructure API Key||
|ibmcloud_api_key|IBM Cloud API Key||
|spectrum_product|IBM Spectrum product that to be installed, either symphony or lsf|symphony|
|cluster_name|the name of cluster|spectrum-cluster|
|domain_name|the name of the domain for the instance|spectrum.ibmcloud|
|data_center|the data center to create resources in||
|public_vlan_id|public VLAN id for master node||
|private_vlan_id|private VLAN id for both master node and private node||
|private_vlan_number|private VLAN number for both master node and compute node||
|master_cores|the number of cpu cores on master node|4|
|master_memory|the amount of memory in MBytes on master node|32768|
|master_disk|the size of disk in GBytes on master node|100|
|master_network_speed|the network interface speed in Mbps for the master nodes|100|
|compute_cores|the number of cpu cores on compute node|2|
|compute_memory|the amount of memory in MBytes on compute node|4096|
|compute_disk|the size of disk in GBytes on compute node|25|
|compute_network_speed|the network interface speed in Mbps for the compute nodes|100|
|remote_console_public_ssh_key|The public key contents for the SSH keypair of remote console for access cluster node||
|scripts_path_uri|the URI of scripts folder for the template|https://raw.githubusercontent.com/chenxpcn/spectrum-ibmcloud-basic/master/scripts|
|installer_uri|the URI of LSF Enterprise Suite installer package||
|entitlement_uri| the URI of IBM Spectrum Symphony entitlement file (this is meaningless for LSF)|n/a|
|cluster_admin_password|the password for administrator user **lsfadmin** for LSF, **egoadmin** for Symphony||
|image_name|the image name of dynamic compute node|SpectrumClusterDynamicHostImage|

