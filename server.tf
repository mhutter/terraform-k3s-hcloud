# Server Firewall
# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
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
}

# Transform Butane to Ignition
data "ct_config" "server" {
  content = yamlencode({
    variant = "fcos"
    version = "1.5.0"

    storage = {
      files = [{
        path = "/etc/sysctl.d/90-ip-forward.conf"
        contents = {
          inline = "net.ipv4.ip_forward = 1"
        }
      }]
    }
    systemd = {
      units = [{
        name    = "nat-masquerading.service"
        enabled = true
        contents = templatefile("${path.module}/bootstrap/nat-masquerading.service", {
          ip_range = hcloud_network_subnet.k3s.ip_range
        })
      }]
    }
  })

  strict   = true
  snippets = local.common_butane_snippets
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

  firewall_ids = [hcloud_firewall.server.id]

  depends_on = [hcloud_network_subnet.k3s]
}

resource "hcloud_server_network" "server" {
  ip         = local.server_ip
  network_id = hcloud_network.internal.id
  server_id  = hcloud_server.server.id
}
