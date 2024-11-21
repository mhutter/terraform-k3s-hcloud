terraform {
  required_providers {
    ct = {
      source  = "poseidon/ct"
      version = "0.13.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.49.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
