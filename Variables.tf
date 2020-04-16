# Azure Options
variable "azure_region" {
  default     = "centralus" # Use region shortname here as it's interpolated into the URLs
  description = "The location/region where the resources are created."
}

variable "azure_env" {
  default = "Dev"
  description = "This is the name of the environment tag, i.e. Dev, Test, etc."
}

variable "azure_rg_name" {
  default = "lab" # This will get a unique timestamp appended
  description = "Specify the name of the new resource group"
}

# Shared Options

variable "username" {
  default = "labadmin"
  description = "Admin username for all VMs"
}

variable "password" {
  default = "P@ssw0rd1234!"
  description = "Admin password for all VMs"
}

variable "vm_size" {
  default = "Standard_DS1_v2"
  description = "Specify the VM Size"
}

variable "server_name" {
  default = "ubuntu"
  description = "Specify the hostname"
}

variable "license_accept" {
  default = "none"
  description = "override with accept in your tfvars to accept the  chef license"
}

variable "policy_name" {
  description = "Specify the name of the desired policy for the -pf- nodes"
}

variable "chef_server_url" {
  description = "Specify the url with org for your chef server i.e. https://chef.example.com/organizations/org_name"
}

variable "chef_user_name" {
  description = "specify the username associated with the key below. used for bootstrapping the new node"
}

variable "chef_user_key" {
  description = "specify the path to the user pem file for the user specified above"
}

variable "chef_client_version" {
  default = "15.8.23"
  description = "Specify the desired chef client version"
}

variable "run_list" {
  default = ""
  description = "Enter the cookbook::recipe that should be included in the runlist for the -env- nodes"
}

variable "hab_origin" {
  default = ""
  description = "Specify the Habitat origin for your effortless packages. This assumes you use BLDR"
}

variable "infra_pkg_name" {
  default = ""
  description = "Specify the name of the effortless infra package for the -ef- nodes"
}

variable "audit_pkg_name" {
  default = ""
  description = "Specify the name of the effortless audit package for the -ef- nodes"
}
