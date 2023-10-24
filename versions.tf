terraform {
  required_providers {
    ct = {
      source  = "poseidon/ct"
      version = "0.13.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.44.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
