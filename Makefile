PLAN := terraform.tfplan
KUBECONFIG := $(shell pwd)/.kubeconfig

.PHONY: help
help: ## Show this help
	@grep -E -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: fmt
fmt:  ## Format all terraform code
	terraform fmt -recursive .

.PHONY: plan
plan:  ## Create a plan
	terraform plan -out=$(PLAN)

.PHONY: apply
apply:  ## Apply the plan
	terraform apply $(PLAN)

.PHONY: lint
lint: fmt validate yamllint  ## Run all linting

.PHONY: validate
validate:  ## Validate the terraform code
	terraform validate

.PHONY: yamllint
yamllint:  ## Validate the Butane files
	yamllint **/*.bu

.PHONY: kubeconfig
kubeconfig:
	$(eval SERVER_IP := $(shell terraform output -raw server_ip))
	$(eval SERVER_INTERNAL_IP := $(shell terraform output -raw server_internal_ip))
	command ssh core@$(SERVER_IP) sudo cat /etc/rancher/k3s/k3s.yaml > $(KUBECONFIG)
	sed -i 's/$(SERVER_INTERNAL_IP)/$(SERVER_IP)/g' $(KUBECONFIG)
	sed -i 's/127.0.0.1/$(SERVER_IP)/g' $(KUBECONFIG)

.PHONY: cilium
cilium:  ## Install Cilium on the cluster
	$(eval SERVER_INTERNAL_IP := $(shell terraform output -raw server_internal_ip))
	cilium install --set operator.replicas=1 --set kubeProxyReplacement=true --set k8sServiceHost=$(SERVER_INTERNAL_IP) --set k8sServicePort=6443

.PHONY: clean
clean:  ## Clean up generated files
	rm -f $(PLAN) $(KUBECONFIG)
