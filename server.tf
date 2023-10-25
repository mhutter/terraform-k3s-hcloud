locals {
  server_labels = merge(local.common_labels, {
    role = "server"
  })
}

resource "hcloud_firewall" "server" {
  name = "k3s-server"

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = var.admin_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.admin_cidrs
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = var.admin_cidrs
  }

  labels = local.server_labels
}

resource "hcloud_volume" "server" {
  name     = "k3s-server-data"
  size     = 10
  location = "fsn1"

  labels = local.server_labels
}

# Transform Butane to Ignition
data "ct_config" "server" {
  strict = true
  content = templatefile("${path.module}/bootstrap/server.bu", {
    agent_token = random_password.agent_token.result
    ip_range    = hcloud_network_subnet.k3s.ip_range
    node_ip     = local.server_ip
    volume_id   = hcloud_volume.server.id
  })
  snippets = [templatefile("${path.module}/bootstrap/common.bu", {
    role = "server"
  })]
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
resource "hcloud_server" "server" {
  name        = "k3s-server"
  image       = data.hcloud_image.arm.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = data.hcloud_ssh_keys.all.*.id
  user_data   = data.ct_config.server.rendered

  network {
    network_id = hcloud_network.k3s.id
    ip         = local.server_ip
  }
  firewall_ids = [hcloud_firewall.server.id]

  labels     = local.server_labels
  depends_on = [hcloud_network_subnet.k3s]
  lifecycle {
    ignore_changes = [image]
  }
}
resource "hcloud_volume_attachment" "server" {
  server_id = hcloud_server.server.id
  volume_id = hcloud_volume.server.id
}
