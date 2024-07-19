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
  description = "SSH public key to be used for all controllers"
  type        = string
  default     = ""
}

variable "admin_cidrs" {
  description = "List of IP CIDR ranges that are allowed to administer the cluster"
  type        = list(string)
  default     = []
}

variable "ip_offsets" {
  description = "Offsets for the IP addresses of the controllers and nodes"
  type        = map(number)
  default = {
    controller = 200
  }
}

# Cluster Configuration
variable "fleetlock_host" {
  description = "IP or hostname under which fleetlock will be available"
  type        = string
  default     = "10.43.0.15"
}

variable "registry_mirrors" {
  description = "(Optional) registry mirrors to use"
  type        = map(string)
  default     = {}
}

locals {
  fallback_ssh_key = file("~/.ssh/id_ed25519.pub")
  ssh_key          = coalesce(var.ssh_key, local.fallback_ssh_key)

  # Networking
  controller_ip = cidrhost(hcloud_network_subnet.k3s.ip_range, var.ip_offsets.controller)

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
