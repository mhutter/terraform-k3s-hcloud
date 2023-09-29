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

# Transform Butane to Ignition
data "ct_config" "server" {
  strict = true
  content = templatefile("${path.module}/bootstrap/server.bu", {
    agent_token = random_password.agent_token.result
    ip_range    = hcloud_network_subnet.k3s.ip_range
    node_ip     = local.server_ip
  })
  snippets = [templatefile("${path.module}/bootstrap/common.bu", {
    role = "server"
  })]
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
resource "hcloud_server" "server" {
  name        = "k3s-server"
  image       = data.hcloud_image.coreos.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.default.id]
  user_data   = data.ct_config.server.rendered

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.internal.id
    ip         = local.server_ip
  }
  firewall_ids = [hcloud_firewall.server.id]

  labels     = local.server_labels
  depends_on = [hcloud_network_subnet.k3s]
}
