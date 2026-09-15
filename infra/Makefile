# Uso: make <alvo> ENV=testnet|mainnet
ENV ?= testnet
TOFU ?= tofu
DIR := tofu/envs/$(ENV)

.PHONY: help init plan apply destroy output fmt validate test sync link ssh info publish

help:
	@echo "Alvos: init plan apply destroy output fmt validate test sync [ORG=<nome>] link info publish [ARGS=--dry-run] ssh NODE=<nó>"
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
