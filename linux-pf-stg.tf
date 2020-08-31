#create a public IP address for the virtual machine
resource "azurerm_public_ip" "linux-pf-stg-pubip" {
  name                = "linux-pf-stg-pubip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "linux-pf-stg-${lower(substr(join("", split(":", timestamp())), 8, -1))}"

  tags = {
    environment = var.azure_env
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "linux-pf-stg-ip" {
  name                = "linux-pf-stg-ip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "linux-pf-stg-ipconf"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.linux-pf-stg-pubip.id
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "linux-pf-stg" {
  name                  = "linux-pf-stg"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.linux-pf-stg-ip.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "linux-pf-stg-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "linux-pf-stg"
    admin_username = var.username
    admin_password = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = var.azure_env
  }

  connection {
    host     = azurerm_public_ip.linux-pf-stg-pubip.fqdn
    type     = "ssh"
    user     = var.username
    password = var.password
  }

  provisioner "chef" {
    client_options  = ["chef_license '${var.license_accept}'"]
    use_policyfile  = "true"
    policy_name     = var.policy_name
    policy_group    = "stg"
    node_name       = "linux-pf-stg"
    server_url      = var.chef_server_url
    recreate_client = true
    user_name       = var.chef_user_name
    user_key        = file(var.chef_user_key)
    version         = var.chef_client_version

    # If you have a self signed cert on your chef server change this to :verify_none
    ssl_verify_mode = ":verify_peer"
  }
}

output "linux-pf-stg-fqdn" {
  value = azurerm_public_ip.linux-pf-stg-pubip.fqdn
}

