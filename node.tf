locals {
  node_labels = merge(local.common_labels, {
    role = "node"
  })
}

resource "hcloud_placement_group" "nodes" {
  name   = "nodes"
  type   = "spread"
  labels = local.node_labels
}
resource "hcloud_firewall" "nodes" {
  name = "k3s-nodes"

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = var.admin_cidrs
  }

  labels = local.node_labels
}

# Transform Butane to Ignition
data "ct_config" "node" {
  count  = local.node_count
  strict = true

  content = templatefile("${path.module}/bootstrap/node.bu", {
    gateway_ip    = cidrhost(hcloud_network_subnet.k3s.ip_range, 1)
    controller_ip = local.controller_ip
    token         = random_password.agent_token.result
  })
  snippets = [
    local.common_butane_snippet,
    templatefile("${path.module}/bootstrap/role.bu", { k3s_role = "agent" }),
  ]
}

resource "random_pet" "node_name" {
  count     = local.node_count
  length    = 2
  separator = "-"

  keepers = {
    placement_group = hcloud_placement_group.nodes.id
    network         = hcloud_network.k3s.id
  }

  lifecycle {
    ignore_changes = [keepers]
  }
}

resource "hcloud_server" "node" {
  count = local.node_count

  name        = random_pet.node_name[count.index].id
  image       = data.hcloud_image.arm.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.k3s.id]
  user_data   = data.ct_config.node[count.index].rendered
  labels      = local.node_labels

  placement_group_id = hcloud_placement_group.nodes.id
  firewall_ids       = [hcloud_firewall.nodes.id]

  network {
    network_id = hcloud_network.k3s.id
  }

  depends_on = [hcloud_network_subnet.k3s]
  lifecycle {
    ignore_changes       = [image, network]
    replace_triggered_by = [random_pet.node_name[count.index].id]
  }
}
