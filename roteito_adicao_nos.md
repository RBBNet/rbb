# Roteiro para adição de novos nós a uma rede RBB

Este roteiro tem como objetivo a adição de novos nós a uma rede RBB já estabelecida e funcional.

**Observação**: Para a criação de uma rede RBB, consulte um dos seguintes roteiros:
- [Roteiro para criação de uma rede](Roteiro_para_a_criacao_de_uma_rede.md)
- [Roteiro para levantar uma rede de testes (toy)](roteiro_criacao_rede_teste.md)

**Observação**: **ESTE ROTEIRO AINDA ESTÁ EM ELABORAÇÃO** e ainda pode sofrer alterações.

## 1 - Preparação de ambiente

### 1.1 - Pré-requisitos

- Hosts para execução de nodes da RBB:

Cada node RBB deve ser executado sobre um host próprio. A seguir são apresentados os valores de referência mínimos recomendados para hosts, tanto da rede Lab quanto da rede Piloto:

- Referência HW/SW para Hosts da Rede Lab:
  - CPU: 2 Cores/vCPU
  - RAM: 4 GB
  - Disco: 100 GB SSD
  - Conectividade de rede: 1G Eth
  - SO: Ubuntu 22.04 Server LTS (atualizar o Ubuntu 20.04 original para Ubuntu 22.04 Server LTS)

- Referência HW/SW para Hosts da Rede Piloto:
  - CPU: 8 Cores/vCPU
  - RAM: 8 GB
  - Disco: 200 GB SSD
  - Conectividade de rede: 1G Eth
  - SO: Ubuntu 22.04 Server LTS


- Outras aplicações:
  - [Docker](https://www.docker.com/products/docker-desktop/)
  - cURL
  - git


### 1.2 - Baixar o repositório `start-network`

- Execute os seguintes comandos:

```bash
curl -#SL https://github.com/RBBNet/start-network/releases/download/v0.4.1+permv1/start-network.tar.gz | tar xz
cd start-network
  ```

Daqui para frente, para cada novo nó, considere que todos os comandos são executados dentro do diretório `start-network`.

## 2 - Criação de novo(s) nó(s)

### 2.1 - Definção de endereço IP externo e porta

Para cada nó será necessário definir um endereço IP e porta para acesso externo pelos demais partícipes ou, especificamente no caso de nó observer-boot, pelo público em geral. A exceção será no caso de nó wirter dos partícipes associados, que será acessível apenas de forma interna a cada partícipe.

É permitido, para fins de redundância e/ou balanceamento de carga, que um nó tenha mais de um endereço IP.

Obs.: Cada nó, na verdade, usa duas portas: uma porta RPC para interação humana (envio de transações, de comandos de gestão etc); e uma porta P2P, para comunicação com outros nós.

### 2.2 - Definição de nomes

Os nós participantes de uma rede RBB devem seguir o [padrão estabelecido](padrao_nomes_nos.md), que compreende o padrão `<tipo_no><sequencial>` (ex.: validator01, boot02). Usualmente, o primeiro nó de um certo tipo tem o sequencial `01`. Fica a cargo de cada partícipe adequar o sequencial de acordo com a configuração desejada em sua infraestrutura.

### 2.3 - Definição de nome de host (Opcional)

Além de endereço IP, um nó também pode ter um *host name*, devidamente configurado em DNS, de forma que possa ser traduzido no(s) endereço(s) IP definidos para o nó.

**Observação**: A definição de *host name* para os nós é **opcional**. A utilização de *host names*, ao invés de endereços IP, é possível através de funcionalidade experimental do Besu e ainda será experimentada na RBB. Porém, a definição de *host names* é incentivada para permitir a realização de futuros experimentos na RBB. 

### 2.4 - Criação de novo(s) nó(s)

Usualmente, cada nó é criado em uma VM separada, dentro de um contêiner Docker. Porém, nada impede que vários nós sejam criadas em diferentes contêineres em uma mesma VM.

Siga um ou vários dos itens a seguir de acordo com o(s) tipo(s) de nó que quiser adicionar à rede.

#### 2.4.1 - Novo boot

- Definir sequencial para o nome do nó. Por exemplo: `boot01` (sequencial `01`).


- Gerar chaves e endereço do nó:

```bash
./rbb-cli node create boot<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:

```bash
./rbb-cli config set nodes.boot<sequencial>.ports+=[\"<porta-rpc>:8545\"]
```

- Definir o endereço IP **externo** e a porta pela qual serão feitas conexões P2P com o nó:

```bash
./rbb-cli config set nodes.boot<sequencial>.address=\"<ip-externo>:<porta-p2p>\"
```

#### 2.4.2 - Novo validator

- Definir sequencial para o nome do nó. Por exemplo: `validator01` (sequencial `01`).

- Gerar chaves e endereço do nó:

```bash
./rbb-cli node create validator<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:
  
```bash
./rbb-cli config set nodes.validator<sequencial>.ports+=[\"<porta-rpc>:8545\"]
```

- Definir o endereço IP **externo** e a porta pela qual serão feitas conexões P2P com o nó:

```bash
./rbb-cli config set nodes.validator<sequencial>.address=\"<ip-externo>:<porta-p2p>\"
```

- Desabilitar a descoberta de nós com o seguinte comando:

```bash
./rbb-cli config set nodes.validator<sequencial>.environment.BESU_DISCOVERY_ENABLED=false
```

#### 2.4.3 - Novo writer

- Definir sequencial para o nome do nó. Por exemplo: `writer01` (sequencial `01`).

- Gerar chaves e endereço do nó:

```bash
./rbb-cli node create writer<sequencial>
```

- Definir a porta pela qual serão feitas chamadas RPC para o nó:

```bash
./rbb-cli config set nodes.writer<sequencial>.ports+=[\"<porta-rpc>:8545\"]
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

#### 2.4.4 - Novo observer-boot

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

**Observarção**: A inteção desse arquivo é ter uma lista de contas **vazia**, de forma **não** permitir conta alguma enviar transações. Deve-se lembrar que o observer-boot é o único tipo de nó da RBB com acesso público e que deve ser utilizado **somente para leitura**.

## 3 - Documentação do(s) novo(s) nó(s)

Com base nas informações definidas no passo anterior, a documentação da RBB deve ser atualizada. As informações dos nós devem ser compartilhadas para que todas as instituições conheçam as informações de todos os nós da rede e possam conectar esses nós conforme a topologia da rede.

Para isso, deve-se documentar as informações definidas no item anterior, acrescentando-as no arquivo localizado no repositório privado, com acesso restrito apenas para os participantes da rede: <https://github.com/RBBNet/participantes>. 

O arquivo é o `nodes.json`, que se encontra em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/nodes.json`, onde `${rede}` pode assumir o valor `lab` (laboratório) ou `piloto`, a depender em qual rede os novos nós devam ser adicionados. 

O arquivo `nodes.json` possui o seguinte formato:


```
[
  {
    "organization": "...",
    "nodes": [
      {
        "name": "...",
        "nodeType": "...",
        "enode": "",
        "hostNames": [ "...", "..." ... ],
        "ipAddresses" : [ "...", "..." ... ],
        "port": ...,
        "id": "..."
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
- `enode` é a chave pública do nó (sem o prefixo `0x`).
- `hostNames` é a lista com os nomes de host do nó, caso exista algum. Caso o nó não tenha nome de host correspondente, não adicione este atributo. Caso o nó tenha apenas um nome de host, preencha a lista com um único elemento.
- `ipAddresses` é a lista de endereços IP do nó. Caso só exista um endereço, preencha a lista com um único elemento.
- `port` é a porta IP utilizada pelo nó.
- `id` é o identificador do nó (com o prefixo `0x`). Este atributo deve ser utilizado para os nós do tipo `validator`.

Em caso de dúvidas, é possível utiliar o [JSON schema](https://github.com/RBBNet/participantes/blob/main/nodes.schema.json) definido para o arquivo `nodes.json` no repositório privado dos participantes.

## 4 - Comunicação

Comunique aos demais partícipes da rede sobre a inclusão de novos nós na rede. Várias atividades deverão ser realizadas em conjunto para o correto funcionamento dos novos nós, logo há necessidade de uma coordenação a partir desse ponto. 

## 5 - Regras de firewall

Os passos 5.1 e 5.2 podem ser executados em paralelo pelo partícipe que está aderindo à rede (5.1) e pelos outros partícipes (5.2). 

As conexões entre os nós writer, boot, validator e observer-boot de uma instituição se dará por endereços IP **internos** e as conexões entre nós de diferentes instituições se dará por endereços IP **externos**. O diagrama a seguir pode ser útil para melhor compreensão.

![Topologia da rede](https://i.imgur.com/BwHFxsf.png)

## 5.1 - Configurações na própria instituição

As seguintes regras de firewall deverão ser configuradas por sua instituição:

- Todos os validators devem conseguir conectar-se entre si. Por isso, para seus validators:
  - Permita conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu validator a partir dos outros validators que integram a RBB.
  - Permita conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos outros validators que integram a RBB.
- Todos os boots devem conseguir conectar-se entre si e com os writers dos **partícipes parceiros**. Por isso, para seus boots:
  - Permita conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu boot a partir dos outros boots que integram a RBB, além dos writers dos **partícipes paceiros**.
  - Permita conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos outros boots que integram a RBB, além dos writers dos **partícipes parceiros**.
- Os observer-boots devem estar acessíveis por qualquer nó da Internet: 
  - Permita conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu observer-boot a partir de **qualquer endereço IP**.

Temos optado por configurar regras tanto para UDP quanto para TCP, embora suspeitemos que UDP seja necessário apenas para nós que participam do discovery (boot e observer-boot). Ainda não testamos, porém, não abrir o UDP para validators e writers.

## 5.2 Configurações pelas demais instituições

As seguintes regras de firewall deverão ser configuradas pelas demais instituições:

- Todos os validators devem conseguir conectar-se entre si. Por isso, os demais partícipes devem realizar confiugrações para que seus validators:
  - Permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus validators a partir dos novos validators adicionados à RBB.
  - Permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos validators adicionados à RBB.
- Todos os boots devem conseguir conectar-se entre si. Por isso, os demais partícipes devem realizar configurações para que seus boots:
  - Permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus boots a partir dos novos boots adicionados à RBB.
  - Permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos boots adicionados à RBB.
- Os writers dos **partícipes parceiros** devem conseguir conectar-se com todos os boots. Por isso, os **partícipes parceiros** devem realizar configurações para que:
  - Seus writers permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus writers a partir dos novos boots adicionados à RBB.
  - Seus writers permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos boots adicionados à RBB.
- Os observer-boots dos **partícipes parceiros** devem conseguir conectar-se com todos os boots. Por isso, os **partícipes parceiros** devem realizar configurações para que:
  - Seus observer-boots permitam conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus observer-boots a partir dos novos boots adicionados à RBB.
  - Seus observer-boots permitam conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos novos boots adicionados à RBB.

# 6 - Permissionamento do(s) novo(s) nó(s)

Para que possam conectar-se à rede, os novos nós precisar ser permissionados. Este permissionamento deve ser feito através de execução dos *smart contracts* da RBB específicos para essa função, que devem ser executados por uma conta de administração.

Solicite que um administrador da rede realize o(s) devido(s) permissionamento(s).

# 7 - Ajustar genesis e static-nodes do(s) novo(s) nó(s) para o novo partícipe

As atividades a seguir deverão ser executadas para cada novo nó, de acordo com seu tipo.

## 7.1 Novo boot

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json`.

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

## 7.2 Novo validator

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json`.

- Crie o arquivo `volumes/validator<sequencial>/static-nodes.json` e inclua todos os **outros** validators da rede (usando endereços IP **externos**) e o nó boot da própria instituição (usando endereço IP **interno**):

```json
[ 
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>", 
  ...
  "enode://<chave-publica-boot-interno-SEM-0x>@<ip-interno>:<porta-p2p>"
]
```

## 7.3 Novo writer

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json`.

- Para **partícipe associado**, crie o arquivo `volumes/writer<sequencial>/static-nodes.json` e inclua o boot interno da própria instituição (usando endereço IP **interno**):

```json
[ 
  "enode://<chave-publica-boot-interno-SEM-0x>@<ip-interno>:<porta-p2p>"
]
```

## 7.4 Novo observer-boot

- Copie para `.env.configs/` o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json`.

- Para **partícipe associado**, crie o arquivo `volumes/observer-boot<sequencial>/static-nodes.json` e inclua o boot interno da própria instituição (usando endereço IP **interno**):

```json
[ 
  "enode://<chave-publica-boot-interno-SEM-0x>@<ip-interno>:<porta-p2p>"
]
```

# 8 - Ajustar genesis e static-nodes dos nós dos outros partícipes associados 

As atividades a seguir deverão ser executadas pelos **partícipes associados** para cada novo nó, de acordo com seu tipo.

## 8.1 Novo boot

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` do boot da instituição o novo boot adicionado à rede (usando endereço IP **externo**):

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 8.2 Novo validator

- Inclua no arquivo `volumes/validator<sequencial>/static-nodes.json` do validator da instituição o novo validator adicionado à rede (usando endereço IP **externo**):

```json
[ 
  ...
  "enode://<chave-publica-validator-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
]
```

# 9 - Ajustar genesis dos nós dos partícipes parceiros  

As atividades a seguir deverão ser executadas pelos **partícipes parceiros** para cada novo nó, de acordo com seu tipo.

## 9.1 - Novo boot na rede - Ajustes no writer e no observer-boot do partícipes parceiro

- Inclua na seção apropriada do arquivo `.env.configs/genesis.json` do writer e do observer-boot (se houver) da instituição o novo boot adicionado à rede (usando endereço IP **externo**):

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-boot-externo-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

# 10 - Iniciar novo(s) nó(s)

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

# 11 - Solicitar votação no(s) novo(s) validator(s)

Para que um novo validador passe a fazer parte do algoritmo de consenso, os demais validadores precisam realizar uma votação para aceitá-lo. Atingindo-se a metade mais um dos votos, o novo validador é aceito.

Caso possua um nó preparado para ser validator, mas ainda sem produzir blocos, avise às outras instituições para que se organize a votação, que, uma vez iniciada deve ser terminada em um determinado limite de tempo. Portanto, esta precisa ser uma atividade coordenada.

A votação deve ser realizada no nó validator de cada partícipe associado através do comando:

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["<id-novo-validator-SEM-0x>",true], "id":1}' <ip-interno-validator>:<porta-json-rpc>
```

Os identificadores dos validadores pode ser obtido em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/nodes.json` no atributo `id` de cada nó.

# 12 - Implantar monitoração

Toda organização deverá fornecer um endpoint Prometheus onde as métricas de seus nós poderão ser coletadas por outras organizações (*cross-service federation*). Na configuração sugerida neste roteiro, um único Prometheus é responsável por ler as métricas de cada nó e disponibilizá-las para outras organizações da RBB. O mesmo Prometheus é usado também para coletar as métricas de outras organizações.

A configuração apresentada aqui é a mais simples que atende ao requisito, embora cada organização possa usar topologias mais complexas. Por exemplo, uma organização pode usar Prometheus individuais para cada nó e agregar as métricas em outro Prometheus para disponibilizar externamente. É possível também usar outro Prometheus isolado para coletar as métricas de outras organizações.

- Defina um servidor para executar o Prometheus e clone o projeto de monitoração:
```
git clone https://github.com/RBBNet/rbb-monitoracao.git
```
O projeto apresenta a seguinte estrutura:
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

## 12.1 - Habilitar as métricas no Besu:
> [!NOTE]
> As configurações a seguir devem ser realizadas em cada nó do Besu.

- Mapeie a porta padrão das métricas (9545) em uma porta do host. O exemplo abaixo usa o script *rbb-cli* para mapear a porta de métricas para o boot na porta 10002 do host. O comando correspondente (assumindo o sequencial do nome como 01: **nodes.<boot01|validator01|writer01>.ports**) deverá ser realizado para os demais nós.

Ex.:
```
./rbb-cli config set nodes.boot01.ports+=[\"<porta-metricas>:9545\"]
```

> [!CAUTION]
> Caso o nome do nó contenha traço, como "observer-boot01", usar o comando no seguinte formato (sob risco de corromper o infra.json):
> 
> `./rbb-cli config set nodes[\"observer-boot01\"].ports+=[\"<porta-metricas>:9545\"]`
  
- Reinicie o container Besu com as novas configurações:
```
docker-compose down
./rbb-cli config render-templates
docker-compose up -d
```

Para maiores detalhes sobre as métricas no Besu, consulte a [documentação](https://besu.hyperledger.org/public-networks/how-to/monitor/metrics).

## 12.2 - Disponibilizar as métricas para outras organizações
> [!NOTE]
> As configurações a seguir devem ser realizadas no servidor do Prometheus.

- Toda organização deverá ter uma configuração no Prometheus (arquivo `prometheus.yml`) que exporta as métricas com os seguintes requisitos:
```
- job_name: rbb
  labels:
    node: <boot01|validator01|writer01|prometheus01|observer-boot01>, conforme o nó de origem da métrica. 
    organization: <nome da organização>
```
O arquivo de configuração do [repositório de monitoração](https://github.com/RBBNet/rbb-monitoracao) apresenta uma configuração (**job_name: rbb**) que atende a esses requisitos. Ele deverá ser alterado com os dados de cada organização.

- Preencher o arquivo **`nodes.json`** em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/nodes.json`:
  - Encontre no arquivo a organização (atributo `organization`) correspondente.
  - Acrescente um nó equivalente ao Prometheus na lista de nós (atributo `nodes`).
  - Informe:
    - Nome (`name`): por exemplo com o valor `prometheus01`.
	- Tipo de nó (`nodeType`): com valor `prometheus`.
    - Nome de host (lista `hostNames`): prencher com lista de nomes, caso exista algum. Caso contrário, não adicionar este atributo.
    - Endereço(s) IP (lista `ipAddresses`): prencher lista de endereços IP. Caso só exista um endereço, preencha uma lista de apenas um elemento.
    - Porta (`port`): porta IP utilizada.

> [!NOTE]
> As devidas liberações de firewall devem ser providenciadas com base nas informações do `nodes.json`.

## 12.3 - Capturar as métricas de outras organizações
A forma de capturar as métricas de outras organizações pode variar bastante. Por exemplo, elas podem ser capturadas com outro Prometheus ou diretamente por dashboards (Grafana, Zabix, etc.). No repositório de monitoração, é apresentada, como exemplo, uma forma de captura com o próprio Prometheus que exporta as métricas locais. Essa configuração pode ser verificada no arquivo `prometheus.yml`, *job_name: rbb_federado*. 

- Alterar os labels dos alvos (*targets*) de cada organização conforme abaixo:
```
- job_name: rbb-federado
  - targets: [<ip do prometheus alvo>:<porta do prometheus alvo>]
    labels:
      organization: <nome da organização>
```
> [!NOTE]
> O job deve ser configurado com os alvos (*targets*) de outras organizações conforme o arquivo **`nodes.json`**.

## 12.4 - Levantar o Prometheus
- Uma vez alterado o arquivo `prometheus.yml`, levante o container do Prometheus:
```
docker-compose up -d
```
- Acesse a interface web do Prometheus e verifique o estado dos alvos (menu *Status -> Targets*), bem como algumas métricas (ex: no menu *Graph*, digite como expressão *ethereum_blockchain_height*).


# 13 - Ajustar monitoração dos outros partícipes

Os demais partícipes devem ajustar a configuração de seus Prometheus, para que passem a capturar as métricas dos novos nós adicionados à rede. Para tanto, faz-se necessário a inclusão de um novo alvo (*target*) no job `rbb-federado`, cadastrado no arquivo `prometheus.yml`:
```
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



# 14 - Implantar block explorer (opcional)

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

# 15 - Cadastar conta admin (opcional)

EM ELABORAÇÃO.

# 16 - Implantar DApp de permissionamento (opcional)

EM ELABORAÇÃO.
