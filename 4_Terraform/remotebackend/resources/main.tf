terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-training-dev-westeu-001"
    storage_account_name = "satrainingdev"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
    access_key           = ""
  }
}
provider "azurerm" {
  features {}
}
data "azurerm_resource_group" "training" {
  name     = "rg-training-dev-westeu-001"
}
resource "azurerm_virtual_network" "training" {
  name                = "training-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.training.location
  resource_group_name = data.azurerm_resource_group.training.name
}
resource "azurerm_subnet" "training" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_network_interface" "training" {
  name                = "training-nic"
  location            = data.azurerm_resource_group.training.location
  resource_group_name = data.azurerm_resource_group.training.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.training.id
  }
}
resource "azurerm_public_ip" "training" {
  name                = "training-publicip"
  location            = data.azurerm_resource_group.training.location
  resource_group_name = data.azurerm_resource_group.training.name
  allocation_method   = "Dynamic"
}
resource "azurerm_windows_virtual_machine" "training" {
  name                = "training-tfs"
  resource_group_name = data.azurerm_resource_group.training.name
  location            = data.azurerm_resource_group.training.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  license_type        = "Windows_Client"
  network_interface_ids = [
    azurerm_network_interface.training.id,
  ]
  os_disk {
    name                 = "training-tfs-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pro-g2"
    version   = "latest"
  }
}
data "azurerm_public_ip" "training" {
  name                = azurerm_public_ip.training.name
  resource_group_name = data.azurerm_resource_group.training.name
}
output "training_vm_ip" {
  value     = data.azurerm_public_ip.training.ip_address
}