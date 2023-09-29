locals {
  common_labels = {
    managed-by = "terraform"
    source     = "github.com_mhutter_terraform-hcloud-k3s"
    env        = terraform.workspace
  }
}

# SSH public key
# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key
resource "hcloud_ssh_key" "default" {
  name       = "default"
  public_key = local.ssh_key
  labels     = local.common_labels
}

data "hcloud_image" "coreos" {
  most_recent       = true
  with_architecture = "arm"
  with_selector     = "os-flavor=coreos"
  with_status       = ["available"]
}

resource "hcloud_network" "internal" {
  name     = "internal"
  ip_range = local.internal_network
  labels   = local.common_labels
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.internal.id
  network_zone = "eu-central"
  ip_range     = local.internal_network
  type         = "cloud"
}

resource "hcloud_network_route" "gateway" {
  network_id  = hcloud_network.internal.id
  destination = "0.0.0.0/0"
  gateway     = local.server_ip
}

resource "random_password" "agent_token" {
  length  = 64
  lower   = true
  upper   = true
  numeric = true
  special = false
}
