PLAN := terraform.tfplan

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
