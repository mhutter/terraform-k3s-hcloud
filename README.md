# K3s on CoreOS on ARM on Hetzner Cloud

Deploy a K3s cluster on Hetzner cloud.

## Features

- Single control plane "server"
- All cluster traffic via internal network
- Automated installation of K3s on all systems
- Cluster bootstrapping
- Nodes automatically join the cluster


## Backlog

- [x] Configure Fleetlock
- [ ] Move Server Data to persistent disk
- [ ] Remove Ports 80+443 from Nodes -> LB
- [ ] Configure node flavors
- [ ] Support x86 nodes


## Usage

For configuration, set

```sh
export KUBECONFIG="${PWD}/.kubeconfig"

# Used for SSH & Kubernetes API access to the server
export TF_VAR_admin_cidrs='["1.2.3.4/32"]'

# Terraform State
export AWS_ACCESS_KEY_ID=''
export AWS_SECRET_ACCESS_KEY=''
export AWS_S3_ENDPOINT=''

# Provider config
export TF_VAR_hcloud_token_dev=''
export TF_VAR_hcloud_token_prod=''
```

Set up OpenTofu:

```sh
tofu init
tofu workspace select dev  # or `prod`
```

And then, `just` do all the things:

```sh
just plan
just apply

# wait a minute until K3s is installed & ready
just kubeconfig
# (repeat if failed)

just install-cilium
```

And that should result in a K3s cluster with three nodes, ready to go!
