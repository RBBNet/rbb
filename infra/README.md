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
| `boot01` | boot | sim | boots, writers de parceiros e observer-boots das outras organizações | VPC | VPC | 400 GB |
| `validator01` | validator | sim | validators das outras organizações | VPC | VPC | 400 GB |
| `writer01` | writer | sim (só SSH) | **somente VPC** (endereço anunciado = IP interno) | VPC + `rpc_cidrs` | VPC | 400 GB |
| `observer-boot01` | observer-boot | sim | internet (0.0.0.0/0) | VPC (ou público com `rpc_public`) | VPC | 400 GB |
| `observer01` (opcional) | observer | sim (só SSH) | **somente VPC**; peers = observer-boots próprios | VPC + `rpc_cidrs` | VPC | 400 GB+ (archive) |
| `prometheus01` | prometheus | sim | — | 8443 `/federate` (NGINX mTLS) para os Prometheus das outras organizações; 443 UI (senha) para admins; 9090 VPC | — | — |

As origens permitidas vêm de `network/participants.json` (IPs reais dos nós ativos das outras organizações, gerados a partir do `nodes.json`), exatamente como o passo 9 do roteiro pede. Com `firewall_from_participants = false` volta-se ao fallback `participant_cidrs` (padrão: qualquer origem). Sempre que outra organização entrar ou trocar de IP, rode `make sync` e `tofu apply` de novo.

Além disso: VPC, subnet pool, sub-rede com IPs privados fixos e estáveis (derivados do tipo e do sequencial: boot01 = .11, validator01 = .21, writer01 = .31, observer-boot01 = .41, observer01 = .51, prometheus01 = .61; adicionar ou remover um nó nunca muda o IP dos outros), um security group por nó (regras padrão da Magalu desabilitadas), chave SSH, IPs públicos gerenciados, volumes de dados criptografados (com `prevent_destroy` em mainnet) e NAT gateway quando algum nó fica sem IP público.

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
- `gh` ([GitHub CLI](https://cli.github.com)) autenticado com uma conta **membro da org RBBNet**: o script `rbb-sync-participantes.sh` lê o repositório privado `RBBNet/participantes` (`genesis.json`, `nodes.json`, `docker-compose.yml.hbs`, certificados). Sem esses arquivos os nós são preparados mas o Besu não é iniciado.
- Chave SSH dos administradores.

## Passo a passo

```bash
cd infra/tofu/envs/testnet            # ou mainnet
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars              # organization, ssh_public_key, admin_ssh_cidrs, ...
export TF_VAR_mgc_api_key="<api key da Magalu Cloud>"

# arquivos da rede, gerados a partir do repositório privado RBBNet/participantes/<lab|piloto>/
# (genesis.json, nodes.json, docker-compose.yml.hbs, boots.txt, validators.txt, federation.json, clients.pem)
../../../scripts/rbb-sync-participantes.sh testnet BNDES     # nome da organização como em nodes.json

tofu init
tofu plan -out=tofu.tfplan
tofu apply tofu.tfplan
tofu output nodes
```

Ou, a partir de `infra/`: `make sync ORG=BNDES ENV=testnet` e `make init plan apply ENV=testnet`.

Aguarde alguns minutos pelo bootstrap (`/var/log/rbb-node-setup.log` em cada VM). Depois:

```bash
cd infra
./scripts/rbb-link-nodes.sh testnet   # aplica a topologia (passo 3 do roteiro) e reinicia os nós
./scripts/rbb-node-info.sh testnet    # trecho para nodes.json + parâmetros de addEnode()
./scripts/rbb-ssh.sh testnet validator01 sudo rbb-node status
```

O script `rbb-sync-participantes.sh` só considera nós das **outras** organizações com `deploymentStatus = deployed` e `operationalStatus = active`, usando o primeiro IP documentado. Repita-o (e depois `rbb-link-nodes.sh`) sempre que o `nodes.json` mudar.

O script `rbb-link-nodes.sh` implementa as regras do roteiro para partícipe associado:

- `validator`: `static-nodes.json` = validators das outras organizações (`network/validators.txt`) + boot(s) próprio(s) com IP interno;
- `writer` e `observer-boot`: `static-nodes.json` = boot(s) próprio(s) com IP interno;
- `boot`: `discovery.bootnodes` do genesis = boots das outras organizações (`network/boots.txt`);
- `prometheus`: instala `network/clients.pem` (certificados dos demais partícipes, mTLS) e `network/federation.json` (Prometheus das demais organizações, sem reiniciar).

No piloto, o `docker-compose.yml.hbs` publicado em `participantes/piloto/` (sem limites de CPU/memória no contêiner) substitui automaticamente o do `start-network`.

### Depois do `apply`: o que a rede precisa receber de você (passos 6 a 13 do roteiro)

Os IPs públicos só existem depois do `tofu apply` (são recursos gerenciados e sobrevivem à recriação das VMs). As outras organizações precisam deles para liberar firewall, incluir seu boot no `discovery` delas e seu validator nos `static-nodes.json` delas. A sequência é:

1. **Documentar os nós** (passo 6): `./scripts/rbb-node-info.sh testnet` coleta chave pública, `id` do validator, IPs e portas e gera `network/our-nodes.json` no formato do `nodes.schema.json` (writer de associado com IP interno, Prometheus na 8443). `./scripts/rbb-publish-nodes.sh testnet` abre um PR em `RBBNet/participantes` com a entrada mesclada (`--dry-run` só mostra o diff). Use `deploymentStatus = provisioned` até o nó estar conectado e mude para `deployed` depois.
2. **Comunicar** (passo 7): anunciar a inclusão em reunião do Comitê Técnico. Só a partir daí as outras organizações ajustam firewall (passo 9.2), `discovery` dos boots e `static-nodes` dos validators (passo 10) e a federação do Prometheus (passo 12).
3. **Permissionar** (passo 8): `rbb-node perm-args` em cada nó imprime `enodeHigh`, `enodeLow`, `NodeType` e o comando pronto. Organização nova: a Governança cria uma proposta com `addOrganization`, `addAccount` (Administrador Global, conta gerada com `generate-key.js` do `scripts-permissionamento`, guardada com alto rigor) e `addNode` para cada nó. Organização já cadastrada: o próprio administrador executa `node-rules-v2.js addLocalNode`. Sem permissionamento os nós não sincronizam.
4. **Ligar a topologia** (passos 3 e 10): `./scripts/rbb-link-nodes.sh testnet`.
5. **Publicar o certificado** do Prometheus (`/srv/rbb/prometheus/certs/certificado.pem`) em `participantes/<rede>/certificados/<org>-prometheus01.pem`. A senha inicial da interface web (443) fica em `/srv/rbb/prometheus/.htpasswd-initial`.
6. **Votar o validator** (passo 13): com o nó sincronizado e monitorado, pedir ao Comitê Técnico a votação `qbft_proposeValidatorVote` pelos validators existentes, usando o `id` impresso por `perm-args`.
7. Se a organização já opera nós, ajuste os sequenciais em `nodes` (ex.: `validator02`). `hostNames` só entram no `nodes.json` se você definir `dns_domain` (e criar os registros DNS `rbb-<nó>.<domínio>` apontando para os IPs públicos).

## Operação do nó (`rbb-node`)

Em qualquer VM, como root (`sudo rbb-node`):

| Comando | Função |
|---|---|
| `info` / `enode [--internal]` / `pubkey` / `perm-args` | identificação do nó, entrada para `nodes.json`, comandos de permissionamento gen02 e voto QBFT |
| `peers show\|set\|add <enode>...` | `volumes/<nó>/static-nodes.json` |
| `bootnodes show\|set\|clear` | `config.discovery.bootnodes` do genesis |
| `genesis set <arquivo>` | instala um genesis |
| `up` / `down` / `restart` / `logs -f` / `status` | ciclo de vida do Besu |
| `cli <args>` | executa `./rbb-cli <args>` em `/srv/rbb/start-network` |
| `prometheus clients <pem>` / `prometheus federation <json>` / `prometheus reload` | nós prometheus |

Do lado local, `scripts/rbb-ssh-keys.sh <env> show|set|add|remove` gerencia as chaves SSH autorizadas em todos os nós, e `scripts/rbb-update-tools.sh <env> [--rerun-setup]` envia versões novas do `rbb-node`/bootstrap para as VMs sem recriá-las (o bootstrap é idempotente e migra os dados para o volume caso ele tenha sido anexado depois do primeiro boot).

O layout na VM é o mesmo do roteiro: `/srv/rbb/start-network/` (rbb-cli, `infra.json`, `.env.configs/`, `volumes/<nó>/`), então qualquer comando dos roteiros oficiais pode ser executado ali.

## Armazenamento do Besu: Bonsai ou Forest

O roteiro da RBB não fixa formato; o `docker-compose.yml.hbs` não define `data-storage-format`, então vale o padrão do Besu 25.5.0, que é **Bonsai** (menor uso de disco e memória, adequado a boot, validator, writer e observer-boot). **Forest** com `sync-mode FULL` só é indicado para um nó archive de leitura, como o observer que alimenta o Blockscout do TCU, porque Bonsai não guarda estado histórico profundo. Para esse caso, adicione um nó com:

```hcl
nodes = {
  "observer-boot02" = { type = "observer-boot", data_volume_size = 800,
    extra_env = { BESU_DATA_STORAGE_FORMAT = "FOREST", BESU_SYNC_MODE = "FULL" } }
}
```

O módulo já tem o tipo `observer` para isso: um nó interno de leitura, fora do núcleo da RBB (não entra no `nodes.json` nem exige permissionamento), com P2P só na VPC, discovery desligado e `static-nodes` apontando para o(s) `observer-boot` da própria organização (`rbb-link-nodes.sh` faz isso). Com `archive = true` ele sobe com Forest + FULL:

```hcl
nodes = {
  observer01 = { type = "observer", archive = true, machine_type = "BV4-8-20", data_volume_size = 400 }
}
```

Recomendação: subir um `observer01` archive na testnet para medir disco e tempo de sincronização, e só então dimensionar o da mainnet. O formato não pode ser trocado depois sem ressincronizar do zero (novo volume).

## Cotas iniciais da Magalu Cloud

Uma conta nova vem com cotas baixas: **3 IPs públicos** e cerca de **1 TB de Block Storage** por região (a API não expõe os números; eles aparecem como `creating_error_quota` e `Insufficient quota ... public_ip`). Peça aumento no console antes da mainnet. Enquanto isso, a topologia cabe na cota com IP público só onde a RBB exige (boot, validator, observer-boot) e os demais nós privados atrás do NAT gateway, acessados por salto SSH pelo primeiro nó público (`output bastion_ip`; os scripts usam `-J` automaticamente):

```hcl
nodes = {
  boot01          = { type = "boot", data_volume_size = 100 }
  validator01     = { type = "validator", data_volume_size = 150 }
  observer-boot01 = { type = "observer-boot", data_volume_size = 100 }
  writer01        = { type = "writer", public_ip = false, data_volume_size = 100 }
  observer01      = { type = "observer", public_ip = false, archive = true, data_volume_size = 300 }
  prometheus01    = { type = "prometheus", public_ip = false, data_volume_size = 0 }  # public_ip = true assim que a cota permitir (federação 8443)
}
```

## Dimensionamento e custos

Os valores padrão seguem a referência do roteiro (Lab: 2 vCPU/4 GB; Piloto: 8 vCPU/8 GB; 400 GB de disco):

| Ambiente | `default_machine_type` | Contêiner Besu (`container_cpus`/`container_memory`) | Volume |
|---|---|---|---|
| testnet | `BV2-4-20` | 2 / 3G | 400 GB `cloud_nvme1k` |
| mainnet | `BV8-16-100` | 6 / 12G | 400 GB `cloud_nvme1k` |

Ajuste por nó com `nodes.<nó>.machine_type` / `data_volume_size`. Para listar tipos disponíveis na sua região: `mgc virtual-machine machine-types list` (CLI da Magalu) ou o data source `mgc_virtual_machine_types`. Cinco VMs + quatro volumes de 400 GB têm custo mensal relevante: reduza a topologia (ex.: só `observer-boot01` para acesso de leitura) quando fizer sentido.

## Segurança

- SSH restrito a `admin_ssh_cidrs`; nunca use `0.0.0.0/0`.
- **Separe titularidade de operação.** A conta na nuvem, o estado do OpenTofu e uma chave SSH institucional (`ssh_authorized_keys`) devem ficar com a organização titular dos nós; o operador técnico usa chave própria e uma API key própria, ambas revogáveis. `scripts/rbb-ssh-keys.sh <env> remove <comentário-da-chave>` revoga um acesso em todos os nós em segundos, sem recriar nada.
- A porta RPC de boot, validator, writer e observer nunca é pública (o módulo rejeita `rpc_public` fora de observer-boot). Aplicações acessam o writer pela VPC ou por `rpc_cidrs`.
- As chaves dos nós ficam no volume de dados (`/srv/rbb/start-network/.env.configs/nodes/<nó>/key`) e sobrevivem à recriação da VM; só são substituídas em reinstalação ou comprometimento, pois exigem novo permissionamento e, no validator, nova votação.
- RPC e métricas só na VPC (mais `rpc_cidrs`). O observer-boot nega qualquer conta (`accounts-allowlist=[]`).
- P2P dos nós núcleo e a porta 8443 do Prometheus ficam restritos aos IPs das outras organizações (`network/participants.json`), por papel, como no passo 9 do roteiro; observer-boot é público por definição.
- `writer01` anuncia o IP interno e só aceita P2P da VPC; para removê-lo totalmente da internet use `public_ip = false`.
- O NAT gateway fica ligado por padrão: na Magalu o IP público só é anexado depois de a VM existir, e o bootstrap (cloud-init) precisa de internet desde o primeiro boot.
- Os arquivos em `envs/<env>/network/` vêm de um repositório restrito aos partícipes e são ignorados pelo git.
- Estado do OpenTofu contém IPs e IDs, não chaves de nós. Guarde-o em backend remoto (`backend.s3.tf.example`, Object Storage da Magalu) com acesso restrito.
- A API key nunca vai para arquivos versionados (`TF_VAR_mgc_api_key`).

## Estrutura

```
infra/
├── Makefile, scripts/            # sync com participantes, link de nós, info/publicação no nodes.json, ssh
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
- `rbb-sync-participantes.sh` depende do `gh` autenticado com uma conta membro da org RBBNet (o repositório `participantes` é privado).
- A Magalu Cloud pode limitar o número de regras por security group; com muitas organizações, o firewall por papel gera dezenas de regras por nó. Se o `apply` falhar por quota, use `firewall_from_participants = false` e `participant_cidrs` com faixas agregadas.
