provider "ct" {}

provider "hcloud" {
  token = {
    dev  = var.hcloud_token_dev
    prod = var.hcloud_token_prod
  }[terraform.workspace]
}

provider "random" {}
