# Roteiro para adição de novos nós a uma rede RBB

Este roteiro tem como objetivo a adição de novos nós a uma rede RBB já estabelecida e funcional.

**Observação**: Para a criação de uma rede RBB, consulte um dos seguintes roteiros:
- [Roteiro para criação de uma rede](Roteiro_para_a_criacao_de_uma_rede.md)
- [Roteiro para levantar uma rede de testes (toy)](roteiro_criacao_rede_teste.md)


## 1 - Preparação de ambiente

### 1.1 - Pré-requisitos

#### Servidores para execução de nodes da RBB:

A seguir são apresentados os valores de referência sugeridos para servidores, para execução de um nó (uma instância Besu), tanto na rede Lab quanto na rede Piloto:

- Servidores para a rede Lab:
  - CPU: 2 Cores/vCPU
  - RAM: 4 GB
  - Disco: 100 GB
  - Conectividade de rede: 1G Eth

- Servidores para a rede Piloto:
  - CPU: 8 Cores/vCPU
  - RAM: 8 GB
  - Disco: 200 GB
  - Conectividade de rede: 1G Eth

#### Outras ferramentas:
  - [Docker](https://www.docker.com/products/docker-desktop/)
  - cURL
  - git

### 1.2 - Download do repositório `start-network`

- Execute os seguintes comandos:
```bash
curl -#SL https://github.com/RBBNet/start-network/archive/refs/tags/v1.0.0.tar.gz | tar xz
mv start-network-1.0.0 start-network
```

### 1.3 - Download do repositório `rbb-monitoracao`

- Execute os seguintes comandos:
```bash
git clone https://github.com/RBBNet/rbb-monitoracao.git
```

**Observação**: O repositório `rbb-monitoracao` é privado. É necessário ter credencial de acesso para leitura do repositório.


## 2 - Criação de novo(s) nó(s)

### 2.1 - Definção de endereço IP externo e porta

Para cada nó será necessário definir um endereço IP e porta para acesso externo pelos demais partícipes ou, especificamente no caso de nó observer-boot, pelo público em geral. A exceção será no caso de nó wirter dos partícipes associados, que será acessível apenas de forma interna a cada partícipe.

É permitido, para fins de redundância e/ou balanceamento de carga, que um nó tenha mais de um endereço IP.

**Observação**: Cada nó, na verdade, usa duas portas: uma porta RPC para interação humana (envio de transações, de comandos de gestão, etc.); e uma porta P2P, para comunicação com outros nós. A porta RPC **não** deve receber acesso externo. A porta P2P é que pode ter que receber conexões externas, dependendo do tipo de nó.

### 2.2 - Definição de nomes

Os nós participantes de uma rede RBB devem seguir a [padronização de nomes estabelecida](padrao_nomes_nos.md) para a RBB, que compreende o padrão `<tipo_no><sequencial>` (ex.: `validator01`, `boot02`). Usualmente, o primeiro nó de um certo tipo tem o sequencial `01`. Fica a cargo de cada partícipe adequar o sequencial de acordo com a configuração desejada em sua infraestrutura.

### 2.3 - Definição de nome de host (Opcional)

Além de endereço IP, um nó também pode ter um *host name*, devidamente configurado em DNS, de forma que possa ser traduzido no(s) endereço(s) IP definidos para o nó.

**Observação**: A definição de *host name* para os nós é **opcional**. A utilização de *host names*, ao invés de endereços IP, é possível através de funcionalidade experimental do Besu e ainda será experimentada na RBB. Porém, a definição de *host names* é incentivada para permitir a realização de futuros experimentos na RBB. 

### 2.4 - Documentação dos nós

Com base na definição dos nós a serem criados, seus endereços, portas e nomes, já é possível documentar essas informações para o conhecimento do restante da rede. Esta documentação é realizada através do arquivo `nodes.json`, que se encontra em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/nodes.json`, onde `${rede}` pode assumir o valor `lab` (laboratório) ou `piloto`, a depender em qual rede os novos nós devam ser adicionados.

O procedimento de documentação dos nós se encontra no passo 6.

### 2.5 - Criação de novo(s) nó(s)

Usualmente, cada nó (instância Besu) é criado em uma VM separada e executado dentro de um contêiner Docker. Porém, nada impede que vários nós sejam criados em diferentes contêineres em uma mesma VM.

Siga um ou vários dos passos a seguir de acordo com o(s) tipo(s) de nó que quiser adicionar à rede.

Para os passos 2.5.x a seguir, considere que todos os comandos são executados dentro do diretório `start-network`, preparado no passo 1.2.

#### 2.5.1 - Novo boot

- Definir sequencial para o nome do nó. Por exemplo: `boot01` (sequencial `01`).

- Gerar chaves e endereço do nó:
```bash
./rbb-cli node create boot<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:
```bash
./rbb-cli config set nodes.boot<sequencial>.ports+=[\"<porta-rpc>:8545\"]
```

- Definir a porta pela qual será feita a leitura de métricas pelo Prometheus:
```bash
./rbb-cli config set nodes.boot<sequencial>.ports+=[\"<porta-metricas>:9545\"]
```

- Definir o endereço IP **externo** e a porta pela qual serão feitas conexões P2P com o nó:
```bash
./rbb-cli config set nodes.boot<sequencial>.address=\"<ip-externo>:<porta-p2p>\"
```

#### 2.5.2 - Novo validator

- Definir sequencial para o nome do nó. Por exemplo: `validator01` (sequencial `01`).

- Gerar chaves e endereço do nó:
```bash
./rbb-cli node create validator<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:
```bash
./rbb-cli config set nodes.validator<sequencial>.ports+=[\"<porta-rpc>:8545\"]
```

- Definir a porta pela qual será feita a leitura de métricas pelo Prometheus:
```bash
./rbb-cli config set nodes.validator<sequencial>.ports+=[\"<porta-metricas>:9545\"]
```

- Definir o endereço IP **externo** e a porta pela qual serão feitas conexões P2P com o nó:
```bash
./rbb-cli config set nodes.validator<sequencial>.address=\"<ip-externo>:<porta-p2p>\"
```

- Desabilitar a descoberta de nós com o seguinte comando:
```bash
./rbb-cli config set nodes.validator<sequencial>.environment.BESU_DISCOVERY_ENABLED=false
```

#### 2.5.3 - Novo writer

- Definir sequencial para o nome do nó. Por exemplo: `writer01` (sequencial `01`).

- Gerar chaves e endereço do nó:
```bash
./rbb-cli node create writer<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:
```bash
./rbb-cli config set nodes.writer<sequencial>.ports+=[\"<porta-rpc>:8545\"]
```

- Definir a porta pela qual será feita a leitura de métricas pelo Prometheus:
```bash
./rbb-cli config set nodes.writer<sequencial>.ports+=[\"<porta-metricas>:9545\"]
```

- Definir o endereço IP e a porta pela qual serão feitas conexões P2P com o nó:
```bash
./rbb-cli config set nodes.writer<sequencial>.address=\"<ip>:<porta-p2p>\"
```

**Observação**: Para o caso de partícipes associados, o writer é acessível apenas internamente. Portanto, o endereço IP será interno. Para o caso de partícipes parceiros, o writer será acessível externamente. Portanto, o endereço IP será externo.

- Desabilitar a descoberta de nós com o seguinte comando:
```bash
./rbb-cli config set nodes.validator<sequencial>.environment.BESU_DISCOVERY_ENABLED=false
```

#### 2.5.4 - Novo observer-boot

- Definir sequencial para o nome do nó. Por exemplo: `observer-boot01` (sequencial `01`).

- Gerar chaves e endereço do nó:
```bash
./rbb-cli node create observer-boot<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:
```bash
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].ports+=[\"<porta-rpc>:8545\"]
```

**Observação**: Como o nome do nó contem um hífen, ao se utilizar o comando `rbb-cli config set`, deve-se delimitar o nome entre `[\"` e `\"]` no formato `nodes[\"<nome>\"]` (sem utilizar ponto), conforme exemplo acima.

- Definir a porta pela qual será feita a leitura de métricas pelo Prometheus:
```bash
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].ports+=[\"<porta-metricas>:9545\"]
```

- Definir o endereço IP **externo** e a porta pela qual serão feitas conexões P2P com o nó:
```bash
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].address=\"<ip-externo>:<porta-p2p>\"
```

- Desligar o permissionamento *on chain* tanto para contas quanto para nós:
```bash
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].environment.BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED=false
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false
```

- Ligar o permissionamento local para contas:
```bash
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].environment.BESU_PERMISSIONS_ACCOUNTS_CONFIG_FILE_ENABLED=true
./rbb-cli config set nodes[\"observer-boot<sequencial>\"].environment.BESU_PERMISSIONS_ACCOUNTS_CONFIG_FILE=\"/var/lib/besu/permissioned-accounts.toml\"
```

- Criar arquivo local de permissionamento de contas `volumes/observer-boot<sequencial>/permissioned-accounts.toml`:
```
accounts-allowlist=[]
```

**Observarção**: A intenção desse arquivo é ter uma lista de contas **vazia**, de forma a **não** permitir que conta alguma envie transações. Deve-se lembrar que o observer-boot é o único tipo de nó da RBB com acesso público e que deve ser utilizado **somente para leitura**.


# 3 - Configuração de novo(s) nó(s)

As atividades a seguir deverão ser executadas para cada novo nó, de acordo com seu tipo.

Para obter informações sobre outros nós já existentes na rede, necessárias para preenchimento de algumas configurações, consulte o arquivo `nodes.json`, que se encontra em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/nodes.json`.

## 3.1 Configuração de novo boot

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/genesis.json`.

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` todos os **outros** boots da rede (usando endereços IP **externos**):

```json
  "discovery": {
    "bootnodes" : 
    [ 
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

Veja o exemplo abaixo:  
![Conteúdo exemplo do arquivo genesis.json](https://i.imgur.com/mdU0lYT.png)

## 3.2 Configuração de novo validator

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/genesis.json`.

- Crie o arquivo `volumes/validator<sequencial>/static-nodes.json` e inclua todos os **outros** validators da rede (usando endereços IP **externos**) e o nó boot da própria organização (usando endereço IP **interno**):

```json
[ 
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
  ...
  "enode://<chave-publica-boot-interno-SEM-0x>@<ip-interno>:<porta-p2p>"
]
```

## 3.3 Configuração de novo writer

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/genesis.json`.

- Para **partícipe associado**, crie o arquivo `volumes/writer<sequencial>/static-nodes.json` e inclua o boot interno da própria organização (usando endereço IP **interno**):

```json
[ 
  "enode://<chave-publica-boot-interno-SEM-0x>@<ip-interno>:<porta-p2p>"
]
```

- Para **partícipe parceiro**, inclua na seção apropriada do arquivo `.env.configs/genesis.json` todos os **outros** boots da rede (usando endereços IP **externos**):

```json
  "discovery": {
    "bootnodes" : 
    [ 
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 3.4 Configuração de novo observer-boot

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/genesis.json`.

- Para **partícipe associado**, crie o arquivo `volumes/observer-boot<sequencial>/static-nodes.json` e inclua o boot interno da própria organização (usando endereço IP **interno**):

```json
[ 
  "enode://<chave-publica-boot-interno-SEM-0x>@<ip-interno>:<porta-p2p>"
]
```

- Para **partícipe parceiro**, inclua na seção apropriada do arquivo `.env.configs/genesis.json` todos os **outros** boots da rede (usando endereços IP **externos**):

```json
  "discovery": {
    "bootnodes" : 
    [ 
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```


# 4 - Início do(s) novo(s) nó(s)

Para cada novo nó:
```bash
./rbb-cli config render-templates
docker-compose up -d
```

Outros comandos úteis:

- Utilize o seguinte comando para visualizar o log do nó:
```bash
docker-compose logs -f
```

- Utilize o seguinte comando para interromper o nó:
```bash
docker-compose down
```


# 5 - Implantação da monitoração

Toda organização deverá fornecer um endpoint Prometheus onde as métricas de seus nós poderão ser coletadas por outras organizações (*cross-service federation*). Na configuração sugerida neste roteiro, um único Prometheus é responsável por ler as métricas de cada nó e disponibilizá-las para outras organizações da RBB. O mesmo Prometheus é usado também para coletar as métricas de outras organizações.

A configuração apresentada aqui é a mais simples que atende esse requisito, embora cada organização possa usar topologias mais complexas. Por exemplo, uma organização pode usar Prometheus individuais para cada nó e agregar as métricas em outro Prometheus para disponibilizar externamente. É possível também usar outro Prometheus isolado para coletar as métricas de outras organizações.

Ainda, também é possível que cada organização reconfigure os critérios de alerta do Prometheus, conforme julgue oportuno.

Para os passos 5.x a seguir, considere que todos os comandos e arquivos devem serão executados ou se encontram dentro do diretório `rbb-monitoracao`, preparado no passo 1.3.

O diretório apresenta a seguinte estrutura:
```
rbb-monitoracao
├── docker-compose.yml      # Arquivo de configuração do container docker Prometheus
└── prometheus
    ├── prometheus.yml      # Arquivo de configuração do Prometheus
    ├── rules.yml           # Arquivo de regras do Prometheus
    ├── web-config.yml      # Arquivo de configuração para a interface web do Prometheus
    └── rules
        ├── alerts.yml      # Arquivo de configuração para critérios de alertas
        └── metrics.yml     # Arquivo de configuração para definição de métricas derivadas
```

## 5.1 - Habilitação das métricas no Besu

As métricas são habilitadas no Besu a partir do parâmetro `--metrics-enabled`. O arquivo `docker-compose.yml` gerado pelo `rbb-cli` cria automaticamente a variável de ambiente `BESU_METRICS_ENABLED` com o valor `true`. Portanto, todos os nós configurados via `rbb-cli` já terão as métricas compartilhadas por padrão.

Ainda, conforme realizado no passo 2.5, durante a criação dos nós, a porta padrão de métricas do Besu (9545) foi exposta via contêiner Docker. Portanto, todos os nós criados seguindo este roteiro já estarão habilitados para a coleta de métricas, bastanto apenas configurar o Prometheus.

Para maiores detalhes sobre as métricas no Besu, consulte a [documentação](https://besu.hyperledger.org/public-networks/how-to/monitor/metrics).

## 5.2 - Disponibilização das métricas para outras organizações

Toda organização deverá ter uma configuração no Prometheus (arquivo `prometheus.yml`) que exporte suas métricas:
```
...
scrape_configs:
  ...
  # Job para coleta das métricas locais.
  # Inclua aqui os alvos de sua organização (métricas do boot, validator, writer e prometheus)
  - job_name: rbb
    ...
    static_configs:
      - targets: ['<ip-no-besu>:<porta-metricas>']
        labels:
          node: '<boot01|validator01|writer01|prometheus01|observer-boot01>'
          organization: '<nome-organizacao>'
```

O arquivo de configuração do [repositório de monitoração](https://github.com/RBBNet/rbb-monitoracao/blob/main/prometheus/prometheus.yml#L48) apresenta uma configuração (`job_name: rbb`) que atende esse objetivo. Ele deverá ser alterado com os dados de sua organização, adicionando um alvo (*target*) para cada nó Besu.

## 5.3 - Captura das métricas de outras organizações

A forma de capturar as métricas de outras organizações pode variar bastante. Por exemplo, elas podem ser capturadas com outro Prometheus ou diretamente por *dashboards* (Grafana, Zabix, etc.). No repositório de monitoração, é apresentada, como exemplo, uma forma de captura com o próprio Prometheus que exporta as métricas locais. Essa configuração (`job_name: rbb_federado`) pode ser verificada no arquivo `prometheus.yml`.

É necessário adicionar um alvo (*target*) para cada uma das demais organizações, conforme abaixo:
```
...
scrape_configs:
  ...
  # Job para coletar as métricas de outras organizações.
  # Inclua aqui os alvos das outras organizações (Prometheus expostos).
  - job_name: rbb-federado
    ...
    static_configs:
      - targets: ['<ip-prometheus-outra-organizacao>:<porta-prometheus-outra-organizacao>']
        labels:
          organization: '<nome-outra-organizacao>'
```

Para configuração dos alvos, utilize as informações dos nós documentados no arquivo `nodes.json`, que se encontra em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/nodes.json`.

## 5.4 - Configuração da autenticação mútua

EM ELABORAÇÃO.

## 5.5 - Início do Prometheus

Para iniciar o contêiner do Prometheus:
```
docker-compose up -d
```

Acesse a interface web do Prometheus (http://localhost:9090/) e verifique o estado dos alvos (menu *Status -> Targets*), bem como algumas métricas (ex: no menu *Graph*, digite como expressão `ethereum_blockchain_height`).


## 6 - Documentação do(s) novo(s) nó(s)

Com base nas informações definidas nos passos anteriores, a documentação da RBB deve ser atualizada. As informações dos nós devem ser compartilhadas para que todas as organizações conheçam as informações de todos os nós da rede e possam conectar esses nós conforme a topologia da RBB.

Para isso, deve-se documentar as informações definidas nos passos anteriores, acrescentando-as no arquivo `nodes.json` localizado no repositório privado (com acesso restrito apenas para os participantes da rede) https://github.com/RBBNet/participantes.

O arquivo se encontra em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/nodes.json`, onde `${rede}` pode assumir o valor `lab` (laboratório) ou `piloto`, a depender em qual rede os novos nós devam ser adicionados. 

O arquivo `nodes.json` possui o seguinte formato:
```json
[
  {
    "organization": "...",
    "nodes": [
      {
        "name": "...",
        "nodeType": "...",
        "pubKey": "",
        "hostNames": [ "...", "..." ... ],
        "ipAddresses" : [ "...", "..." ... ],
        "port": ...,
        "id": "...",
        "deploymentStatus": "...",
        "operationalStatus": "..."
      }
      ...
    ]
  }
  ...
]
```

Onde:
- `organization` é nome da organização.
- `nodes` é a lista de nós da organização.
- `name` é o nome do nó, conforme o [padrão de nomes da RBB](padrao_nomes_nos.md).
- `nodeType` é o tipo do nó, podendo ser um dos seguintes valores: `boot`, `validator`, `writer`, `observer-boot` ou `prometheus`.
- `pubKey` é a chave pública do nó (com o prefixo `0x`).
- `hostNames` é a lista com os nomes de host do nó, caso exista algum. Caso o nó não tenha nome de host correspondente, não adicione este atributo. Caso o nó tenha apenas um nome de host, preencha a lista com um único elemento.
- `ipAddresses` é a lista de endereços IP do nó. Caso só exista um endereço, preencha a lista com um único elemento.
- `port` é a porta IP utilizada pelo nó.
- `id` é o identificador do nó (com o prefixo `0x`). Este atributo deve ser utilizado para os nós do tipo `validator`. O identificador do nó deve ser obtido no arquivo `.env.configs/nodes/<nome-do-no>/node.id`.
- `deploymentStatus` indica o estado de implantação do nó na rede, podendo ser um dos seguintes valores:
  - `provisioned`: caso o nó já tenha chave pública, identificador (no caso de validator), endereço IP e porta definidos, porém sem ainda estar plenamente implantado.
  - `deployed`: caso o nó já tenha sido implantado e já possa receber conexões.
  - `retired`: caso o nó esteja sendo ou já tenha sido definitivamente desconectado e desligado.
- `operationalStatus` indica o estado operacional do nó:
  - `inactive` indica que o nó está temporariamente inativo, como por exemplo quando está sofrendo manutenção.
  - `active` indica que o nó está (ou deveria estar) ativo.

Em caso de dúvidas, é possível utiliar o [JSON schema](https://github.com/RBBNet/participantes/blob/main/nodes.schema.json) definido para o arquivo `nodes.json` no repositório privado dos participantes.


## 7 - Comunicação

Comunique aos demais partícipes da rede sobre a inclusão de novos nós na rede. Várias atividades deverão ser realizadas em conjunto para o correto funcionamento dos novos nós. Logo, há necessidade de uma coordenação a partir desse ponto. Independentemente a quaisquer outros canais de comunicação que venham a ser utilizados, **a inclusão dos novos nós deve ser anunciada e discutida em reunião do Comitê Técnico da RBB**.


# 8 - Permissionamento do(s) novo(s) nó(s)

Para que possam conectar-se à rede, os novos nós precisam ser permissionados. Isto deve ser feito através de execução dos [*smart contracts* de permissionamento](https://github.com/RBBNet/Permissionamento/) da RBB.

Para o caso de novas organizações, o permissionamento terá que ser feito através de uma atividade de governança *on chain*. Nesse caso, solicite ao Comitê Técnico a realização do [procedimento de inclusão da nova organização](https://github.com/RBBNet/Permissionamento/blob/main/gen02/doc/macroprocessos.md#entrada-de-uma-nova-organiza%C3%A7%C3%A3o).

Para o caso de novo(s) nó(s) de uma organização já existente, utilize uma conta administrativa de sua organização para o permissionamento do(s) novo(s) nó(s). O permissionamento de novos nós deverá ser feito através da função [`NodeRulesV2Impl.addLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string calldata name)`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/NodeRulesV2Impl.sol#L48), onde:
- `enodeHigh`: São os primeiros 32 bytes da chave pública do nó.
- `enodeLow`: São os útimos 32 bytes da chave pública do nó.
- `nodeType`: Indica um dos tipos definidos pela enumeração [`NodeType`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/NodeRulesV2.sol#L11)
- `name`: Nome do nó, conforme documentado no arquivo `nodes.json` (ver passo 6).

Outras funções disponíveis para a gestão de nós são:
- `deleteLocalNode(bytes32 enodeHigh, bytes32 enodeLow)`: Remove nó.
- `updateLocalNode(bytes32 enodeHigh, bytes32 enodeLow, NodeType nodeType, string memory name)`: Atualiza dados do nó.
- `updateLocalNodeStatus(bytes32 enodeHigh, bytes32 enodeLow, bool active)`: Habilita ou desabilita o nó.

O endereço para o *smart contract* `NodeRulesV2Impl` pode ser encontrado em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/contratos.md`, onde `${rede}` pode assumir o valor `lab` (laboratório) ou `piloto`, a depender em qual rede o permissionamento será feito.

Mais informações sobre a gestão e permissionamento de nós podem ser encontradas na [documentação dos *smart contracts* de permissionamento*](https://github.com/RBBNet/Permissionamento/blob/main/gen02/doc/nos.md).

Para facilitar a chamada aos *smart contracts* de permissionamento, é possível usar os [scripts de permissionamento](https://github.com/RBBNet/scripts-permissionamento) ou o [DApp de permissionamento](https://github.com/RBBNet/dapp-permissionamento). Saiba mais sobre essas duas ferramantas nos arquivos README desses projetos.


## 9 - Regras de firewall

Os passos 9.1 e 9.2 podem ser executados em paralelo pelo partícipe que está aderindo à rede (9.1) e pelos outros partícipes (9.2). 

As conexões entre os nós writer, boot, validator e observer-boot de uma organização se dará por endereços IP **internos** e as conexões entre nós de diferentes organizações se dará por endereços IP **externos**. O diagrama a seguir pode ser útil para melhor compreensão.

![Topologia da rede](https://i.imgur.com/BwHFxsf.png)

## 9.1 - Configurações na própria organização

As seguintes regras de firewall deverão ser configuradas por sua organização:

- Todos os validators devem conseguir conectar-se entre si. Por isso, para seus validators:
  - Permita conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu validator a partir dos outros validators que integram a RBB.
  - Permita conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos outros validators que integram a RBB.
- Todos os boots devem conseguir conectar-se entre si e com os writers dos **partícipes parceiros**. Por isso, para seus boots:
  - Permita conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu boot a partir dos outros boots que integram a RBB, além dos writers dos **partícipes paceiros**.
  - Permita conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos outros boots que integram a RBB, além dos writers dos **partícipes parceiros**.
- Os observer-boots devem estar acessíveis por qualquer nó da Internet: 
  - Permita conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu observer-boot a partir de **qualquer endereço IP**.
- Todos os Prometheus devem conseguir conectar-se entre si. Por isso, para seu Prometheus:
  - Permita conexão (inbound) no `<ip-externo>:<porta-prometheus>` do seu Prometheus a partir dos outros Prometheus que integram a RBB.
  - Permita conexão (outbound) para os `<ip-externo>:<porta-prometheus>` dos outros Prometheus que integram a RBB.

**ATENÇÃO**: Para que o mecanismo de *discovery* dos nós funcione, é necessário configurar as regras tanto para UDP quanto para TCP. **Habilite acesso UDP nos seguintes casos**:
- Conexões entre nós boot.
- Conexões externas (de qualquer origem) aos nós observer-boot.
- Conexões entre nós writer de partícipes parceiros com boots de partícipes associados.

## 9.2 Configurações pelos demais partícipes

As seguintes regras de firewall deverão ser configuradas pelas demais organizações:

- Todos os validators devem conseguir conectar-se entre si. Por isso, os demais partícipes devem realizar configurações para que seus validators:
  - Permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus validators a partir dos novos validators adicionados à RBB.
  - Permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos validators adicionados à RBB.
- Todos os boots devem conseguir conectar-se entre si. Por isso, os demais partícipes devem realizar configurações para que seus boots:
  - Permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus boots a partir dos novos boots adicionados à RBB.
  - Permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos boots adicionados à RBB.
- Os writers dos **partícipes parceiros** devem conseguir conectar-se com todos os boots. Por isso, os **partícipes parceiros** devem realizar configurações para que:
  - Seus writers permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus writers a partir dos novos boots adicionados à RBB.
  - Seus writers permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos boots adicionados à RBB.
- Os observer-boots dos **partícipes parceiros** devem conseguir conectar-se com todos os boots. Por isso, os **partícipes parceiros** devem realizar configurações para que:
  - Seus observer-boots permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus observer-boots a partir qualquer endereço IP.
  - Seus observer-boots permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos boots adicionados à RBB.
- Todos os Prometheus devem conseguir conectar-se entre si. Por isso, os demais partícipes devem realizar configurações para que seus Prometheus:
  - Permitam conexão (inbound) no `<ip-externo>:<porta-prometheus>` dos seus Prometheus a partir dos novos Prometheus adicionados à RBB.
  - Permitam conexão (outbound) para os `<ip-externo>:<porta-prometheus>` dos novos Prometheus adicionados à RBB.

**ATENÇÃO**: Para que o mecanismo de *discovery* dos nós funcione, é necessário configurar as regras tanto para UDP quanto para TCP. **Habilite acesso UDP nos seguintes casos**:
- Conexões entre nós boot.
- Conexões entre nós writer de partícipes parceiros com boots de partícipes associados.
- Conexões entre nós observer-boot de partícipes parceiros com boots de partícipes associados.


# 10 - Ajustes de configurações dos outros partícipes associados 

As atividades a seguir deverão ser executadas pelos **partícipes associados** para cada novo nó, de acordo com seu tipo.

## 10.1 Novo boot

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` do boot da organização o novo boot adicionado à rede (usando endereço IP **externo**):

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 10.2 Novo validator

- Inclua no arquivo `volumes/validator<sequencial>/static-nodes.json` do validator da organização o novo validator adicionado à rede (usando endereço IP **externo**):

```json
[ 
  ...
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
]
```

## 10.3 Novo writer de partícipe parceiro

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` do boot da organização o novo writer adicionado à rede (usando endereço IP **externo**):

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-writer-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 10.4 Novo observer-boot de partícipe parceiro

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` do boot da organização o novo observer-boot adicionado à rede (usando endereço IP **externo**):

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-observer-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 10.5 Novo Prometheus

Para ajustar a configuração do Prometheus, siga as instruções descritas no passo 12 - Ajustes de configuração na monitoração pelos demais partícipes.


# 11 - Ajustes de configurações dos partícipes parceiros 

As atividades a seguir deverão ser executadas pelos **partícipes parceiros** para cada novo nó, de acordo com seu tipo.

## 11.1 - Novo boot na rede - Ajustes no writer e no observer-boot do partícipes parceiro

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` do writer e do observer-boot (se houver) da organização o novo boot adicionado à rede (usando endereço IP **externo**):

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 11.2 Novo Prometheus

Para ajustar a configuração do Prometheus, siga as instruções descritas no passo 12 - Ajustes de configuração na monitoração pelos demais partícipes.


# 12 - Ajustes de configuração na monitoração pelos demais partícipes

Os demais partícipes devem ajustar a configuração de seus Prometheus, para que passem a capturar as métricas dos novos nós adicionados à rede. Para tanto, faz-se necessário a inclusão de um novo alvo (*target*) no job `rbb-federado`, cadastrado no arquivo `prometheus.yml`:
```
...
scrape_configs:
  ...
  # Job para coletar as métricas de outras organizações.
  # Inclua aqui os alvos das outras organizações (Prometheus expostos).
  - job_name: rbb-federado
    ...
    static_configs:
      ...
      - targets: [ '<ip do novo prometheus>:<porta do novo prometheus>' ]
        labels:
          organization: '<nome da organização do novo prometheus>'
```

Após o ajuste no arquivo, deve-se realizar a recarga da configuração no Prometheus. Recomendamos que o contêiner Docker do Prometheus seja reiniciado:
```
docker-compose restart
```

**Observação**: Esse comando deve ser executado na pasta onde estiver o arquivo `docker-compose.yml` do Prometheus.

Opcionalmente, caso não se queira reiniciar o contêiner, é possível sinalizar ao Prometheus a necessidade de recarga de configuração durante sua execução, sem parada do serviço. Mais informações sobre esse procedimento podem ser obtidas na [documentação do Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/configuration/).


# 13 - Votação do(s) novo(s) validator(s)

Para que um novo validador passe a fazer parte do algoritmo de consenso, os demais validadores precisam realizar uma votação para aceitá-lo. Atingindo-se maioria simples dos validadores (50% mais um), o novo validador é aceito.

Caso possua um nó preparado para ser validator, mas ainda sem produzir blocos, traga o caso ao Comitê Técnico da RBB para que se organize a votação, que, uma vez iniciada deve ser terminada em um determinado limite de tempo. Portanto, esta precisa ser uma atividade coordenada.

A votação deve ser realizada no nó validator de cada partícipe associado através do comando:

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["<id-novo-validator-SEM-0x>",true], "id":1}' <ip-interno-validator>:<porta-json-rpc>
```

Os identificadores dos validadores podem ser obtidos em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/nodes.json` no atributo `id` de cada nó.

**Observação**: Essa atividade somente deve ser realizada se o nó a ser votado como validador estiver efetivamente funcional, conectado com os demais validadores e devidamente sincronizado. Adicionalmente, é importante que o novo validador esteja sendo monitorado através do Prometheus da mesma organização e que as métricas desse Prometheus estejam sendo capturadas pelos demais partícipes. Dessa forma, aumenta-se a confiança de que eventuais problemas no novo validador serão detectáveis.


# 14 - Implantação de block explorer (opcional)

## Chainlens Block Explorer

- Executar no node que irá executar o block explorer:
```bash
git clone -n https://github.com/web3labs/chainlens-free

cd chainlens-free

git checkout 484e254563948ac147795ee393af6b547ffef02d > /dev/null 2>&1

cd docker-compose

sed -i "s/WS_API_URL=http:\/\//WS_API_URL=ws:\/\//g" docker-compose.yml

NODE_ENDPOINT=http://<ip-interno-node>:<porta-rpc> PORT=<porta-blockexplorer> docker-compose -f docker-compose.yml -f chainlens-extensions/docker-compose-besu.yml up
```

- Acessar no browser remoto:
```bash
http://<ip-interno-node>:<porta-blockexplorer>
```


# 15 - Permissionamento de contas (opcional)

Ao aderir à RBB, uma nova organização é adicionada ao [permissionamento](https://github.com/RBBNet/Permissionamento/) da rede. E caso essa organização vá implantar nós, é necessário também definir uma conta administrativa. Essa conta é usada para representar a organização em atividades de [governança](https://github.com/RBBNet/Permissionamento/blob/main/gen02/doc/governanca.md) e para atividades de gestão dos próprios nós e contas transacionais - contas que podem enviar transações para a rede, mas não podem realizar atividades de governança ou permissionamento.

A gestão e o permissionamento de contas deverão ser feitos através do *smart contract* [`AccountRulesV2Impl`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/AccountRulesV2Impl.sol), utilizando-se as funções:
- `addLocalAccount(address account, bytes32 roleId, bytes32 dataHash)`: Adiciona conta.
- `deleteLocalAccount(address account)`: Remove conta.
- `updateLocalAccount(address account, bytes32 roleId, bytes32 dataHash)`: Atualiza dados da conta.
- `updateLocalAccountStatus(address account, bool active)`: Habilita ou desabilita a conta.
- `setAccountTargetAccess(address account, bool restricted, address[] calldata allowedTargets)`: Controla o acesso da conta a *targets* específicos.

O endereço para o *smart contract* `AccountRulesV2Impl` pode ser encontrado em `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/contratos.md`, onde `${rede}` pode assumir o valor `lab` (laboratório) ou `piloto`, a depender em qual rede o permissionamento será feito.

Mais informações sobre a gestão e permissionamento de contas podem ser encontradas na [documentação dos *smart contracts* de permissionamento*](https://github.com/RBBNet/Permissionamento/blob/main/gen02/doc/contas.md).

Para facilitar a chamada aos *smart contracts* de permissionamento, é possível usar os [scripts de permissionamento](https://github.com/RBBNet/scripts-permissionamento) ou o [DApp de permissionamento](https://github.com/RBBNet/dapp-permissionamento). Saiba mais sobre essas duas ferramantas nos arquivos README desses projetos.


# 16 - Implantação do DApp de permissionamento (opcional)

O DApp de permissionamento é uma aplicação web3 que pode ser executada localmente, utilizando uma *wallet* (como o MetaMask, por exemplo) conectada à RBB (rede Lab ou Piloto), para efetuar chamadas às [funções de permissionamento da RBB](https://github.com/RBBNet/Permissionamento), implementadas *on chain*. O DApp funciona como um *"front end"* para os *smart contracts* de permissionamento da RBB.

Para implantar o DApp, consulte o [README do projeto](https://github.com/RBBNet/dapp-permissionamento).

**Observações**:
- A execução de funções que alterem o estado do permissionamento requererá o uso de contas administrativas.
- A guarda de chaves privadas deve ser feito com **alto rigor de segurança**.
- Alternativamente ou complementarmente ao DApp, pode-se também usar os [scripts de permissionamento](https://github.com/RBBNet/scripts-permissionamento). Esses scripts são uma alternativa CLI (*command line interface*) para acesso às funcionalidades dos *smart contracts* de permissionamento da RBB.
