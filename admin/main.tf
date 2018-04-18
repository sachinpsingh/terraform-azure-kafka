locals {
  location       = "${lookup(var.resource_group, "location")}"
  resource_group = "${lookup(var.resource_group, "name")}"
  name           = "${var.name}-admin"
  vm_size        = "${var.vm_size}"

  subnet_id             = "${lookup(var.subnet, "id")}"
  subnet_address_prefix = "${lookup(var.subnet, "address_prefix")}"

  username       = "${var.username}"
  ssh_public_key = "${var.ssh_public_key}"
  image_id       = "${data.azurerm_image.kafka.id}"
}

resource "azurerm_availability_set" "admin" {
  name                = "${local.name}-availset"
  location            = "${local.location}"
  resource_group_name = "${local.resource_group}"
}

resource "azurerm_network_interface" "admin" {
  name                = "${format("%s-nic", local.name)}"
  location            = "${local.location}"
  resource_group_name = "${local.resource_group}"

  ip_configuration {
    name                          = "${format("%s-ipconfig", local.name)}"
    subnet_id                     = "${local.subnet_id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(local.subnet_address_prefix, 5)}"
  }
}

resource "azurerm_virtual_machine" "admin" {
  name                  = "${format("%s-vm", local.name)}"
  location              = "${local.location}"
  resource_group_name   = "${local.resource_group}"
  network_interface_ids = ["${azurerm_network_interface.admin.id}"]
  vm_size               = "${local.vm_size}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${local.image_id}"
  }

  storage_os_disk {
    name              = "${format("%s-osdisk", local.name)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${format("%s", local.name)}"
    admin_username = "${local.username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "${format("/home/%s/.ssh/authorized_keys", local.username)}"
      key_data = "${file("${local.ssh_public_key}")}"
    }
  }

  tags {
    role = "admin"
  }
}