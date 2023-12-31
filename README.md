# K3s on CoreOS on ARM on Hetzner Cloud

Deploy a K3s cluster on Hetzner cloud.


## Features

- Single control plane "controller" (or "server" in K3s lingo)
- All cluster traffic via internal network
- Automated installation of K3s on all systems
- Cluster bootstrapping
- Nodes automatically join the cluster
- Controller & Nodes can be replace


### Non-Goals

- HA control plane


## Backlog

- [ ] Configure node flavors
- [ ] Support x86 nodes


## Setup

For configuration, set

```sh
export KUBECONFIG="${PWD}/.kubeconfig"

# Used for SSH & Kubernetes API access to the controller
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


NOTE: The CoreOS autoupdater expects [poseidon/fleetlock](https://github.com/poseidon/fleetlock) to run on the cluster, using `10.43.0.15` as the Service IP (configure via `fleetlock_url` TF var).


## Day two operations

### Replacing the controller

The Controller can just be replaced at any time. All data is persisted onto an external disk. To be on the safe side, stop the `k3s` service on the Controller before shutting it down.


### Replacing a node

To gracefully replace a node, follow these steps:

1. Let OpenTofu forget the server: `tofu state rm 'hcloud_server.node[N]` where `N` is any of the servers
1. Provision a new node: `just plan`, `just apply`
1. Once the new node is ready, drain the old one.
1. Manually delete the old server and `kubectl delete node` it from the cluster.
