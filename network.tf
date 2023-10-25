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

resource "hcloud_load_balancer" "ingress" {
  name               = "k3s-ingress"
  load_balancer_type = "lb11"
  location           = "fsn1"
  labels             = local.node_labels
}

resource "hcloud_load_balancer_network" "ingress" {
  load_balancer_id = hcloud_load_balancer.ingress.id
  network_id       = hcloud_network.k3s.id
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
  depends_on       = [hcloud_load_balancer_network.ingress]
}
