# Provider configuration per env
variable "hcloud_token_dev" {
  default   = ""
  sensitive = true
  type      = string
}
variable "hcloud_token_prod" {
  default   = ""
  sensitive = true
  type      = string
}

# Global configuration
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
    lb     = 3
    nodes  = 10
  }
}

locals {
  fallback_ssh_key = file("~/.ssh/id_ed25519.pub")
  ssh_key          = coalesce(var.ssh_key, local.fallback_ssh_key)

  # Networking
  server_ip = cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.server)

  env = {
    dev = {
      internal_network = "10.1.0.0/24"
      node_count       = 1
    }
    prod = {
      internal_network = "10.0.0.0/24"
      node_count       = 3
    }
  }

  // IP range for the internal network
  internal_network = local.env[terraform.workspace].internal_network
  // Number of worker nodes
  node_count = local.env[terraform.workspace].node_count
}
