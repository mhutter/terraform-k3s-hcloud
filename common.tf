locals {
  common_butane_snippets = [
    templatefile("${path.module}/bootstrap/common.bu", {
      ssh_key = local.ssh_key
    })
  ]
}

# SSH public key
# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key
resource "hcloud_ssh_key" "default" {
  name       = "default"
  public_key = local.ssh_key
}

data "hcloud_image" "coreos" {
  most_recent       = true
  with_architecture = "arm"
  with_selector     = "os-flavor=coreos"
  with_status       = ["available"]
}

resource "hcloud_network" "internal" {
  name     = "internal"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.internal.id
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
  type         = "cloud"
}

resource "hcloud_network_route" "gateway" {
  network_id  = hcloud_network.internal.id
  destination = "0.0.0.0/0"
  gateway     = local.server_ip
}
