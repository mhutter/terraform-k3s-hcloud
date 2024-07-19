locals {
  controller_labels = merge(local.common_labels, {
    role = "controller"
  })
}

resource "hcloud_firewall" "controller" {
  name = "k3s-controller"

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

  labels = local.controller_labels
}

resource "hcloud_volume" "controller" {
  name     = "k3s-controller-data"
  size     = 10
  location = "fsn1"

  labels = local.controller_labels
}

# Transform Butane to Ignition
data "ct_config" "controller" {
  strict = true
  content = templatefile("${path.module}/bootstrap/controller.bu", {
    agent_token   = random_password.agent_token.result
    ip_range      = hcloud_network_subnet.k3s.ip_range
    controller_ip = local.controller_ip
    volume_id     = hcloud_volume.controller.id
  })
  snippets = [
    local.common_butane_snippet,
    templatefile("${path.module}/bootstrap/role.bu", { k3s_role = "server" }),
  ]
}

resource "hcloud_server" "controller" {
  name        = "k3s-controller"
  image       = data.hcloud_image.arm.id
  server_type = "cax11"
  location    = "fsn1"
  ssh_keys    = [hcloud_ssh_key.k3s.id]
  user_data   = data.ct_config.controller.rendered

  network {
    network_id = hcloud_network.k3s.id
    ip         = local.controller_ip
  }
  firewall_ids = [hcloud_firewall.controller.id]

  labels     = local.controller_labels
  depends_on = [hcloud_network_subnet.k3s]
}

resource "hcloud_volume_attachment" "controller" {
  server_id = hcloud_server.controller.id
  volume_id = hcloud_volume.controller.id
}
