locals {
  common_labels = {
    managed-by = "terraform"
    source     = "github.com_mhutter_terraform-hcloud-k3s"
    env        = terraform.workspace
  }
}

# SSH public key
data "hcloud_ssh_keys" "all" {}

data "hcloud_image" "arm" {
  most_recent       = true
  with_architecture = "arm"
  with_selector     = "os-flavor=coreos"
  with_status       = ["available"]
}

resource "hcloud_network" "k3s" {
  name     = "k3s"
  ip_range = local.internal_network
  labels   = local.common_labels
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.k3s.id
  network_zone = "eu-central"
  ip_range     = local.internal_network
  type         = "cloud"
}

resource "random_password" "agent_token" {
  length  = 64
  lower   = true
  upper   = true
  numeric = true
  special = false
}
