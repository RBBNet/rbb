# Infraestrutura como código para nós da RBB (OpenTofu)

Este diretório automatiza, com [OpenTofu](https://opentofu.org) (open source, compatível com Terraform), a criação da infraestrutura de uma organização partícipe da Rede Blockchain Brasil, seguindo o [roteiro de adição de nós](../roteiro_adicao_nos.md), o [padrão de nomes](../padrao_nomes_nos.md) e o [guia do rbb-cli](../guia_rbb-cli.md).

O código é **genérico**: a parte que descreve um nó RBB (bootstrap, portas, firewall) não depende de provedor de nuvem. A implementação inicial usa a **Magalu Cloud** (provider `magalucloud/mgc`); outros provedores podem ser adicionados implementando um módulo com o mesmo contrato (ver [Portando para outro provedor](#portando-para-outro-provedor)).

Há dois ambientes, com estados independentes:

| Ambiente | Rede RBB | Diretório | Uso |
|---|---|---|---|
| `testnet` | `lab` (laboratório) | `tofu/envs/testnet` | homologação, testes de adesão |
| `mainnet` | `piloto` (produção, chainId 12120014) | `tofu/envs/mainnet` | operação com dados reais |

## O que é criado

Para cada ambiente, com a topologia padrão de **partícipe associado**:

| Nó | Tipo | IP público | P2P (30303 tcp/udp) | RPC 8545 | Métricas 9545 | Volume |
|---|---|---|---|---|---|---|
| `boot01` | boot | sim | partícipes (`participant_cidrs`) | VPC | VPC | 400 GB |
| `validator01` | validator | sim | partícipes | VPC | VPC | 400 GB |
| `writer01` | writer | sim (só SSH) | **somente VPC** (endereço anunciado = IP interno) | VPC + `rpc_cidrs` | VPC | 400 GB |
| `observer-boot01` | observer-boot | sim | internet (0.0.0.0/0) | VPC (ou público com `rpc_public`) | VPC | 400 GB |
| `prometheus01` | prometheus | sim | — | 443 (NGINX mTLS) para partícipes; 9090 VPC | — | — |

Além disso: VPC, subnet pool, sub-rede com IPs privados fixos, um security group por nó (regras padrão da Magalu desabilitadas), chave SSH, IPs públicos gerenciados, volumes de dados criptografados (com `prevent_destroy` em mainnet) e NAT gateway quando algum nó fica sem IP público.

Cada VM é configurada por **cloud-init** no primeiro boot (`modules/rbb-node-config/files/rbb-node-setup.sh`):

1. formata e monta o volume de dados em `/srv/rbb`;
2. instala Docker (repositório oficial) e o shim `docker-compose`;
3. cria o usuário de serviço `rbb`;
4. baixa o [`start-network`](https://github.com/RBBNet/start-network) na versão fixada (`v1.2.0`) e fixa `IMAGE_BESU=hyperledger/besu:25.5.0` (exigência da RBB: Besu ≤ 25.5.0);
5. executa `rbb-cli node create`, `config set` (portas, `address`, `BESU_DISCOVERY_ENABLED`, permissionamento local do observer-boot) e `render-templates`;
6. instala o `genesis.json` (se fornecido) e inicia o Besu com `docker compose up -d`;
7. instala o utilitário `rbb-node` para operação do nó.

As **chaves privadas dos nós são geradas na própria VM** e nunca passam pelo estado do OpenTofu.

## Pré-requisitos

- [OpenTofu ≥ 1.11](https://opentofu.org/docs/intro/install/), `jq`, `ssh`, `make` (opcional).
- Conta na Magalu Cloud com [API key](https://docs.magalu.cloud/docs/devops-tools/api-keys/overview) e quota para as VMs.
- Acesso ao repositório privado `RBBNet/participantes` (concedido pela Governança da RBB após a adesão) para obter `genesis.json`, `nodes.json` e certificados. Sem esses arquivos os nós são preparados mas o Besu não é iniciado.
- Chave SSH dos administradores.

## Passo a passo

```bash
cd infra/tofu/envs/testnet            # ou mainnet
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars              # organization, ssh_public_key, admin_ssh_cidrs, ...
export TF_VAR_mgc_api_key="<api key da Magalu Cloud>"

# arquivos da rede (repositório privado RBBNet/participantes/<lab|piloto>/)
cp /caminho/genesis.json network/genesis.json
$EDITOR network/boots.txt network/validators.txt   # enodes das OUTRAS organizações, um por linha

tofu init
tofu plan -out=tofu.tfplan
tofu apply tofu.tfplan
tofu output nodes
```

Ou, a partir de `infra/`: `make init plan apply ENV=testnet`.

Aguarde alguns minutos pelo bootstrap (`/var/log/rbb-node-setup.log` em cada VM). Depois:

```bash
cd infra
./scripts/rbb-link-nodes.sh testnet   # aplica a topologia (passo 3 do roteiro) e reinicia os nós
./scripts/rbb-node-info.sh testnet    # trecho para nodes.json + parâmetros de addEnode()
./scripts/rbb-ssh.sh testnet validator01 sudo rbb-node status
```

O script `rbb-link-nodes.sh` implementa as regras do roteiro para partícipe associado:

- `validator`: `static-nodes.json` = validators das outras organizações (`network/validators.txt`) + boot(s) próprio(s) com IP interno;
- `writer` e `observer-boot`: `static-nodes.json` = boot(s) próprio(s) com IP interno;
- `boot`: `discovery.bootnodes` do genesis = boots das outras organizações (`network/boots.txt`);
- `prometheus`: instala `network/clients.pem` (certificados dos demais partícipes) para o mTLS.

### Passos que continuam manuais (dependem da Governança)

1. **Permissionamento on chain** dos novos nós (`addEnode`) por um administrador da rede: use a saída de `rbb-node-info.sh` (`enodeHigh`, `enodeLow`, `nodeType`, `name`, `organization`). Sem isso os nós não sincronizam.
2. **Documentar os nós** em `RBBNet/participantes/<rede>/nodes.json` (passo 6 do roteiro), com o JSON gerado por `rbb-node-info.sh`.
3. **Publicar o certificado** do Prometheus (`/srv/rbb/prometheus/certs/certificado.pem` no nó `prometheus01`) em `participantes/<rede>/certificados` e configurar `prometheus_federation_targets` com os Prometheus das demais organizações.
4. Se a organização já opera nós, ajuste os sequenciais em `nodes` (ex.: `validator02`).

## Operação do nó (`rbb-node`)

Em qualquer VM, como root (`sudo rbb-node`):

| Comando | Função |
|---|---|
| `info` / `enode [--internal]` / `pubkey` / `perm-args` | identificação do nó |
| `peers show\|set\|add <enode>...` | `volumes/<nó>/static-nodes.json` |
| `bootnodes show\|set\|clear` | `config.discovery.bootnodes` do genesis |
| `genesis set <arquivo>` | instala um genesis |
| `up` / `down` / `restart` / `logs -f` / `status` | ciclo de vida do Besu |
| `cli <args>` | executa `./rbb-cli <args>` em `/srv/rbb/start-network` |
| `prometheus clients <pem>` / `prometheus reload` | nós prometheus |

O layout na VM é o mesmo do roteiro: `/srv/rbb/start-network/` (rbb-cli, `infra.json`, `.env.configs/`, `volumes/<nó>/`), então qualquer comando dos roteiros oficiais pode ser executado ali.

## Dimensionamento e custos

Os valores padrão seguem a referência do roteiro (Lab: 2 vCPU/4 GB; Piloto: 8 vCPU/8 GB; 400 GB de disco):

| Ambiente | `default_machine_type` | Contêiner Besu (`container_cpus`/`container_memory`) | Volume |
|---|---|---|---|
| testnet | `BV2-4-20` | 2 / 3G | 400 GB `cloud_nvme1k` |
| mainnet | `BV8-16-100` | 6 / 12G | 400 GB `cloud_nvme1k` |

Ajuste por nó com `nodes.<nó>.machine_type` / `data_volume_size`. Para listar tipos disponíveis na sua região: `mgc virtual-machine machine-types list` (CLI da Magalu) ou o data source `mgc_virtual_machine_types`. Cinco VMs + quatro volumes de 400 GB têm custo mensal relevante: reduza a topologia (ex.: só `observer-boot01` para acesso de leitura) quando fizer sentido.

## Segurança

- SSH restrito a `admin_ssh_cidrs`; nunca use `0.0.0.0/0`.
- RPC e métricas só na VPC (mais `rpc_cidrs`). O observer-boot nega qualquer conta (`accounts-allowlist=[]`).
- P2P dos nós núcleo pode ser limitado aos IPs dos partícipes (`participant_cidrs`, a partir de `nodes.json`).
- `writer01` anuncia o IP interno e só aceita P2P da VPC; para removê-lo totalmente da internet use `public_ip = false` (um NAT gateway é criado para a saída).
- Estado do OpenTofu contém IPs e IDs, não chaves de nós. Guarde-o em backend remoto (`backend.s3.tf.example`, Object Storage da Magalu) com acesso restrito.
- A API key nunca vai para arquivos versionados (`TF_VAR_mgc_api_key`).

## Estrutura

```
infra/
├── Makefile, scripts/            # atalhos locais (link de nós, ssh, info)
└── tofu/
    ├── modules/
    │   ├── rbb-node-config/      # AGNÓSTICO: cloud-init + regras de firewall de um nó RBB
    │   │   ├── files/            # rbb-node-setup.sh, rbb-node, prometheus-*
    │   │   └── templates/        # cloud-init.yaml.tftpl, prometheus.yml.tftpl
    │   └── mgc-rbb-stack/        # MAGALU CLOUD: rede, SG, VMs, volumes, IPs (+ tests/)
    └── envs/
        ├── testnet/              # rede lab
        └── mainnet/              # rede piloto
```

## Testes sem credenciais

```bash
make validate   # tofu validate nos dois ambientes
make test       # tofu test com provider mockado (topologia, firewall, NAT, proteção de volumes)
```

## Portando para outro provedor

O contrato é simples: implemente um módulo `tofu/modules/<provedor>-rbb-stack` que

1. receba `organization`, `rbb_network`, `nodes` (mesmo objeto de `mgc-rbb-stack/variables.tf`), CIDRs, chave SSH e `genesis_json`;
2. para cada nó, chame `modules/rbb-node-config` com `private_ip`, `public_ip`, `vpc_cidr` etc., e use `user_data` (cloud-init) e `firewall_rules` (lista `{direction, protocol, port_min, port_max, cidr}`) nos recursos equivalentes (VM, security group, IP público, volume);
3. exponha `output "nodes"` com `type`, `public_ip`, `private_ip`, `p2p_address`.

Os scripts em `scripts/` e o `rbb-node` funcionam sem alteração, pois dependem apenas desse output e do layout na VM.

## Limitações conhecidas

- O bootstrap assume imagem **Ubuntu** (apt). Para outra distribuição, adapte `install_docker` em `rbb-node-setup.sh`.
- O `rbb-cli` usa a imagem `bndes/rbb:latest` do Docker Hub (a mesma do roteiro). Se preferir construí-la, use `build.sh` do `start-network` na VM.
- Alterações no cloud-init após a criação não recriam a VM (`ignore_changes = [user_data]`); use `rbb-node` ou recrie o nó explicitamente (`tofu apply -replace`).
- Os arquivos do repositório privado `participantes` não são obtidos automaticamente.
