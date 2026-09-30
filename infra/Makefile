# Uso: make <alvo> ENV=testnet|mainnet
ENV ?= testnet

# Credenciais (Magalu, AWS do backend S3) vêm de infra/.env, carregado automaticamente se existir.
ifneq (,$(wildcard .env))
include .env
export
endif
TOFU ?= tofu
DIR := tofu/envs/$(ENV)

.PHONY: help init plan apply destroy output fmt validate test sync link ssh info publish cost status

help:
	@echo "Alvos: init plan apply destroy output fmt validate test sync [ORG=<nome>] link info publish [ARGS=--dry-run] status cost ssh NODE=<nó>"
	@echo "Ambiente atual: ENV=$(ENV) ($(DIR))"

init:
	cd $(DIR) && $(TOFU) init

plan:
	cd $(DIR) && $(TOFU) plan -out=tofu.tfplan

apply:
	cd $(DIR) && $(TOFU) apply tofu.tfplan

destroy:
	@[ "$(ENV)" != "mainnet" ] || { read -p "Destruir MAINNET? digite 'sim': " r; [ "$$r" = "sim" ]; }
	cd $(DIR) && $(TOFU) destroy

output:
	cd $(DIR) && $(TOFU) output -json nodes | jq

fmt:
	$(TOFU) fmt -recursive tofu

validate:
	@for e in testnet mainnet; do (cd tofu/envs/$$e && $(TOFU) init -backend=false -input=false >/dev/null && $(TOFU) validate) || exit 1; done

test:
	cd tofu/modules/mgc-rbb-stack && $(TOFU) init -backend=false -input=false >/dev/null && $(TOFU) test

sync:
	./scripts/rbb-sync-participantes.sh $(ENV) $(ORG)

link:
	./scripts/rbb-link-nodes.sh $(ENV)

ssh:
	./scripts/rbb-ssh.sh $(ENV) $(NODE)

info:
	./scripts/rbb-node-info.sh $(ENV)

publish:
	./scripts/rbb-publish-nodes.sh $(ENV) $(ARGS)

status:
	./scripts/rbb-status-config.sh $(ENV) && cd tools/rbb-status && go run . report --config ../../tofu/envs/$(ENV)/network/rbb-status.json

cost:
	@command -v mgc-infra-costs >/dev/null || { echo "instale: go install github.com/poperador/mgc-infra-costs/cmd/mgc-infra-costs@latest"; exit 1; }
	cd $(DIR) && $(TOFU) plan -input=false -refresh=false -out=/tmp/rbb-cost.tfplan >/dev/null && $(TOFU) show -json /tmp/rbb-cost.tfplan | jq 'del(.variables)' > /tmp/rbb-cost.json && rm -f /tmp/rbb-cost.tfplan && mgc-infra-costs breakdown --plan /tmp/rbb-cost.json --region br-se1
