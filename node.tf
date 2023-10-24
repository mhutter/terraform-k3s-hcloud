locals {
  node_ips = [for i in range(local.node_count) : cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.nodes + i)]
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

  rule {
    description = "HTTP"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    description = "HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  labels = local.node_labels
}

# Transform Butane to Ignition
data "ct_config" "node" {
  count  = local.node_count
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
  count     = local.node_count
  length    = 2
  separator = "-"

  keepers = {
    user_data       = md5(data.ct_config.node[count.index].rendered)
    placement_group = hcloud_placement_group.nodes.id
    network         = hcloud_network.k3s.id
  }
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/node
resource "hcloud_server" "node" {
  count = local.node_count

  name        = random_pet.node_name[count.index].id
  image       = data.hcloud_image.arm.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = data.hcloud_ssh_keys.all.*.id
  user_data   = data.ct_config.node[count.index].rendered
  labels      = local.node_labels

  placement_group_id = hcloud_placement_group.nodes.id
  firewall_ids       = [hcloud_firewall.nodes.id]

  network {
    network_id = hcloud_network.k3s.id
    ip         = local.node_ips[count.index]
  }

  depends_on = [hcloud_network_subnet.k3s]
  lifecycle {
    ignore_changes       = [image]
    replace_triggered_by = [random_pet.node_name[count.index].id]
  }
}

resource "hcloud_load_balancer" "ingress" {
  name               = "k3s-ingress"
  load_balancer_type = "lb11"
  location           = "fsn1"
  labels             = local.node_labels
}
resource "hcloud_load_balancer_network" "ingress" {
  load_balancer_id = hcloud_load_balancer.ingress.id
  network_id       = hcloud_network.k3s.id
  ip               = cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.lb)
}
resource "hcloud_load_balancer_service" "ingress" {
  for_each = {
    http  = 80,
    https = 443,
  }

  load_balancer_id = hcloud_load_balancer.ingress.id
  protocol         = "tcp"
  listen_port      = each.value
  destination_port = each.value
  proxyprotocol    = true
  health_check {
    protocol = "http"
    port     = 80
    interval = 10
    timeout  = 5
    http {
      path         = "/healthz"
      status_codes = ["200"]
    }
  }
}
resource "hcloud_load_balancer_target" "ingress" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.ingress.id
  label_selector   = "role=node"
  use_private_ip   = true
}
