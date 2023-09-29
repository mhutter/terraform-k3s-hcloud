locals {
  node_ips = [for i in range(var.node_count) : cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.nodes + i)]
  node_labels = merge(local.common_labels, {
    role = "node"
  })
}

resource "hcloud_firewall" "node" {
  name = "k3s-node"

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = var.admin_cidrs
  }

  labels = local.node_labels
}

resource "hcloud_placement_group" "nodes" {
  name   = "nodes"
  type   = "spread"
  labels = local.node_labels
}

# Transform Butane to Ignition
data "ct_config" "node" {
  count  = var.node_count
  strict = true

  content = templatefile("${path.module}/bootstrap/node.bu", {
    gateway_ip = cidrhost(hcloud_network_subnet.k3s.ip_range, 1)
    node_ip    = local.node_ips[count.index]
    server     = local.server_ip
    token      = random_password.agent_token.result
  })
  snippets = [templatefile("${path.module}/bootstrap/common.bu", {
    role = "agent"
  })]
}

resource "random_pet" "node_name" {
  count     = var.node_count
  length    = 2
  separator = "-"

  keepers = {
    image_id        = data.hcloud_image.coreos.id
    user_data       = md5(data.ct_config.node[count.index].rendered)
    placement_group = hcloud_placement_group.nodes.id
    network         = hcloud_network.internal.id
  }
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/node
resource "hcloud_server" "node" {
  count = var.node_count

  name        = random_pet.node_name[count.index].id
  image       = data.hcloud_image.coreos.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = data.hcloud_ssh_keys.all.*.id
  user_data   = data.ct_config.node[count.index].rendered
  labels      = local.node_labels

  placement_group_id = hcloud_placement_group.nodes.id

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.internal.id
    ip         = local.node_ips[count.index]
  }

  depends_on = [hcloud_network_subnet.k3s]
  lifecycle {
    replace_triggered_by = [random_pet.node_name[count.index].id]
  }
}
