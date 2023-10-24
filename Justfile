tf         := "tofu"
plan       := tf + ".tfplan"

# Format all {{tf}} code
fmt:
	{{tf}} fmt -recursive .

# Create a plan
plan:
	{{tf}} plan -out="{{plan}}"

# Apply the plan
apply:
	{{tf}} apply "{{plan}}"

# Run all linting
lint: fmt validate yamllint

# Validate the {{tf}} code
validate:
	{{tf}} validate

# Validate the Butane files
yamllint:
	yamllint **/*.bu

# Generate administrator kubeconfig
kubeconfig:
	#!/usr/bin/env bash
	set -euxo pipefail
	server_ip="$({{tf}} output -raw server_ip)"
	server_internal_ip="$({{tf}} output -raw server_internal_ip)"
	command ssh "core@${server_ip}" sudo cat /etc/rancher/k3s/k3s.yaml > "${KUBECONFIG}"
	sed -i "s/${server_internal_ip}/${server_ip}/g" "${KUBECONFIG}"
	sed -i "s/127.0.0.1/${server_ip}/g" "${KUBECONFIG}"

# Install Cilium on the cluster
install-cilium:
	#!/usr/bin/env bash
	set -euxo pipefail
	server_internal_ip="$({{tf}} output -raw server_internal_ip)"
	cilium install \
		--set operator.replicas=1 \
		--set kubeProxyReplacement=true \
		--set "k8sServiceHost=${server_internal_ip}" \
		--set k8sServicePort=6443 \
		--set 'ipam.operator.clusterPoolIPv4PodCIDRList={10.42.0.0/16}'

# Clean up generated files
clean:
	rm -f "{{plan}}" "${KUBECONFIG}"
