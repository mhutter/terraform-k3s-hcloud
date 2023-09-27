# node Firewall
# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
resource "hcloud_firewall" "node" {
  name = "k3s-node"

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = var.admin_cidrs
  }
}

# Transform Butane to Ignition
data "ct_config" "node" {
  content  = file("${path.module}/bootstrap/node.bu")
  strict   = true
  snippets = local.common_butane_snippets
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/node
resource "hcloud_server" "node" {
  count = var.node_count

  name        = "k3s-node-${count.index}"
  image       = data.hcloud_image.coreos.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.default.id]
  user_data   = data.ct_config.node.rendered

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.internal.id
    ip         = cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.nodes + count.index)
  }

  depends_on = [hcloud_network_subnet.k3s]
}
