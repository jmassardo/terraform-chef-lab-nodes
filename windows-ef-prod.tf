#create a public IP address for the virtual machine
resource "azurerm_public_ip" "win-ef-prod-pubip" {
  name                = "win-ef-prod-pubip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "win-ef-prod-${lower(substr(join("", split(":", timestamp())), 8, -1))}"

  tags = {
    environment = var.azure_env
  }
}

#create the network interface and put it on the proper vlan/subnet
resource "azurerm_network_interface" "win-ef-prod-ip" {
  name                = "win-ef-prod-ip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "win-ef-prod-ipconf"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.win-ef-prod-pubip.id
  }
}

#create the actual VM
resource "azurerm_virtual_machine" "win-ef-prod" {
  name                  = "win-ef-prod"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.win-ef-prod-ip.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "win-ef-prod-osdisk"
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
    computer_name  = "win-ef-prod"
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
    host     = azurerm_public_ip.win-ef-prod-pubip.fqdn
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "60m"
    user     = var.username
    password = var.password
  }

  provisioner "file" {
    source      = "files/Install-Habitat.ps1"
    destination = "c:/terraform/Install-Habitat.ps1"
  }

  provisioner "remote-exec" {
    inline = [
      "PowerShell.exe -ExecutionPolicy Bypass c:/terraform/Install-Habitat.ps1",
    ]
  }

  provisioner "file" {
    source      = "files/audit_user.toml"
    destination = "C:/hab/user/${var.audit_pkg_name}/config/user.toml"
  }

  provisioner "file" {
    source      = "files/infra_user.toml"
    destination = "C:/hab/user/${var.infra_pkg_name}/config/user.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "hab svc load ${var.hab_origin}/${var.audit_pkg_name} --channel prod --strategy at-once",
      "hab svc load ${var.hab_origin}/${var.infra_pkg_name} --channel prod --strategy at-once",
    ]
  }
}

output "win-ef-prod-fqdn" {
  value = azurerm_public_ip.win-ef-prod-pubip.fqdn
}

