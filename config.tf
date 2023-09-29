variable "ssh_key" {
  description = "SSH public key to be used for all servers"
  type        = string
  default     = ""
}

variable "admin_cidrs" {
  description = "List of IP CIDR ranges that are allowed to administer the cluster"
  type        = list(string)
  default     = []
}

variable "ip_offsets" {
  description = "Offsets for the IP addresses of the servers and nodes"
  type        = map(number)
  default = {
    server = 2
    nodes  = 10
  }
}

variable "node_count" {
  type    = number
  default = 1
}

locals {
  fallback_ssh_key = file("~/.ssh/id_ed25519.pub")
  ssh_key          = coalesce(var.ssh_key, local.fallback_ssh_key)

  # Networking
  server_ip = cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.server)

  env = {
    dev = {
      internal_network = "10.1.0.0/24"
    }
    prod = {
      internal_network = "10.0.0.0/24"
    }
  }

  // IP range for the internal network
  internal_network = local.env[terraform.workspace].internal_network
}
