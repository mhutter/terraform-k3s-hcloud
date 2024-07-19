locals {
  common_labels = {
    managed-by = "terraform"
    source     = "github.com_mhutter_terraform-hcloud-k3s"
    env        = terraform.workspace
  }

  common_butane_snippet = templatefile("${path.module}/bootstrap/common.bu", {
    fleetlock_host = var.fleetlock_host
    registry_config = yamlencode({
      mirrors = {
        for registry, mirror in var.registry_mirrors : registry => {
          "endpoint" = [mirror]
        }
      }
    }),
  })
}

# SSH public key
resource "hcloud_ssh_key" "k3s" {
  name       = "k3s"
  public_key = local.ssh_key
}

data "hcloud_image" "arm" {
  most_recent       = true
  with_architecture = "arm"
  with_selector     = "os-flavor=coreos"
  with_status       = ["available"]
}

resource "random_password" "agent_token" {
  length  = 64
  lower   = true
  upper   = true
  numeric = true
  special = false
}
