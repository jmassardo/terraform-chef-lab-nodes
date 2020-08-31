#create a public IP address for the virtual machine
resource "azurerm_public_ip" "win-env-stg-pubip" {
  name                = "win-env-stg-pubip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "win-env-stg-${lower(substr(join("", split(":", timestamp())), 8, -1))}"

  tags = {
    environment = var.azure_env
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "win-env-stg-ip" {
  name                = "win-env-stg-ip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "win-env-stg-ipconf"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.win-env-stg-pubip.id
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "win-env-stg" {
  name                  = "win-env-stg"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.win-env-stg-ip.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "win-env-stg-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = "win-env-stg"
    admin_username = var.username
    admin_password = var.password
    custom_data    = file("./files/winrm.ps1")
  }

  os_profile_windows_config {
    provision_vm_agent = true
    winrm {
      protocol = "http"
    }

    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("./files/FirstLogonCommands.xml")
    }
  }

  tags = {
    environment = var.azure_env
  }

  connection {
    host     = azurerm_public_ip.win-env-stg-pubip.fqdn
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "60m"
    user     = var.username
    password = var.password
  }

  provisioner "chef" {
    client_options  = ["chef_license '${var.license_accept}'"]
    run_list        = [var.run_list]
    environment     = "stg"
    node_name       = "windows-env-stg"
    server_url      = var.chef_server_url
    recreate_client = true
    user_name       = var.chef_user_name
    user_key        = file(var.chef_user_key)
    version         = var.chef_client_version

    # If you have a self signed cert on your chef server change this to :verify_none
    ssl_verify_mode = ":verify_peer"
  }
}

output "win-env-stg-fqdn" {
  value = azurerm_public_ip.win-env-stg-pubip.fqdn
}

