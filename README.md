# K3s on CoreOS on ARM on Hetzner Cloud

Deploy a K3s cluster on Hetzner cloud.

## Features

- Single control plane "server"
- All cluster traffic via internal network; only the "server" has a public IP (and acts as a NAT gateway)
- Automated installation of K3s on all systems
- Cluster bootstrapping
- Nodes automatically join the cluster


## Backlog

- [ ] Configure node flavors
- [ ] Support x86 nodes


## Usage

For configuration, set

```sh
export KUBECONFIG="${PWD}/.kubeconfig"

# Used for SSH & Kubernetes API access to the server
export TF_VAR_admin_cidrs='["1.2.3.4/32"]'
export TF_VAR_node_count='3'

# Terraform State
export AWS_ACCESS_KEY_ID=''
export AWS_SECRET_ACCESS_KEY=''
export AWS_S3_ENDPOINT=''

# Provider config
export HCLOUD_TOKEN=''
```

And then, `make` all the things:

```sh
make plan
make apply

# wait a minute until K3s is installed & ready
make kubeconfig
# (repeat if failed)

make cilium
```

And that should result in a K3s cluster with three nodes, ready to go!
