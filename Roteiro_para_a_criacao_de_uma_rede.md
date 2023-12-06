
# Roteiro para a criação de uma rede

<picture>
  <img src="https://i.imgur.com/C4FMtOZ.png"></img>
</picture>

Este roteiro tem como objetivo levantar uma cópia compatível com a RBB do zero.

**Após a existência de uma versão inicial da rede, a adição de novas instituições deverá seguir outro roteiro**.

*É fácil confundir, pois este roteiro tem como premissa que as instituições entrarão na rede uma a uma. Porém, não é possível usar este roteiro para adesão de uma instituição após a existência da rede, porque na seção 1 é necessário que os passos sejam executados por todas as instituições em paralelo antes de qualquer nó ser levantado. Logo, uma nova instituição após a rede já existir não terá executado aqueles passos.*  

## 1 - Atividades iniciais a serem executadas em paralelo para todas as instituições

As atividades desta seção devem ser executadas no início da implantação da rede por todas as instituições que irão aderir à rede. Além disso, devem ser executadas em cada máquina virtual (Virtual Machine - VM) em que cada nó será alocado.

### 1.1 - Pré-requisitos

- [Docker](https://www.docker.com/products/docker-desktop/)
- cURL

  ```bash
  sudo apt install curl
  
  ```

### 1.2 - Baixar o repositório `start-network`

- Execute os seguintes comandos:

  ```bash
  curl -#SL https://github.com/RBBNet/start-network/releases/download/v0.4.0-permv1/start-network.tar.gz | tar xz
  cd start-network

  ```

Daqui para frente, considere que todos os comandos são executados dentro do diretório start-network.

### 1.3 - Preparar arquivos

Todos os participantes deverão gerar, ao mesmo tempo, os endereços e as chaves públicas e privadas dos próprios nós.

Execute o comando/script abaixo em cada VM para gerar as chaves e o endereço do nó correspondente ao tipo de nó a ser levantado na VM. Exemplo:

- Gerar chaves e endereço de apenas 1 nó Validator em uma VM:

  ```bash
  ./rbb-cli node create validator
  
  ```
  
  - Ainda na VM do nó validator, execute o comando abaixo para definir a porta da VM pela qual serão feitas chamadas RPC para o nó. No exemplo abaixo é mapeado a porta 10001 da VM (host) para a porta 8545 do nó (container), a porta 8545 do nó é a porta padrão para chamadas RPC via HTTP:

    ```bash
    ./rbb-cli config set nodes.validator.ports+=[\"10001:8545\"]
    
    ```

  - Execute o comando abaixo para definir o IP externo e a porta da VM pela qual serão feitas conexões P2P com o nó validator. No exemplo abaixo é definido o IP externo do nó e a porta 10303 para conexões P2P. A porta 30303 é a porta padrão para conexões P2P, para este caso, no entanto, é definida uma porta diferente da padrão:

    ```bash
    ./rbb-cli config set nodes.validator.address=\"<IP-Externo-Validator>:10303\"

    ```

- Gerar chaves e endereço de apenas 1 nó Boot em uma VM:

  ```bash
  ./rbb-cli node create boot
  
  ```

  - Ainda na VM do nó boot, execute o comando abaixo para definir a porta da VM pela qual serão feitas chamadas RPC para o nó:

    ```bash
    ./rbb-cli config set nodes.boot.ports+=[\"10001:8545\"]
    
    ```

  - Execute o comando abaixo para definir o IP externo e a porta da VM pela qual serão feitas conexões P2P com o nó boot:

    ```bash
    ./rbb-cli config set nodes.boot.address=\"<IP-Externo-Boot>:10304\"

    ```

- Gerar chaves e endereço de apenas 1 nó Writer em uma VM:

  ```bash
  ./rbb-cli node create writer
  
  ```
  
  - Ainda na VM do nó writer, execute o comando abaixo para definir a porta da VM pela qual serão feitas chamadas RPC para o nó:

    ```bash
    ./rbb-cli config set nodes.writer.ports+=[\"10001:8545\"]
    
    ```

  - Execute o comando abaixo para definir o IP interno e a porta da VM pela qual serão feitas conexões P2P com o nó writer:

    ```bash
    ./rbb-cli config set nodes.boot.address=\"<IP-Interno-Writer>:10305\"

    ```

Após a execução dos comandos acima os seguintes itens foram gerados:

- Par de chaves pública/privada:
  - Caminho da chave privada: `.env.configs/nodes/<nome-do-nó>/key`
  - Caminho da chave pública: `.env.configs/nodes/<nome-do-nó>/key.pub`
- Endereço do nó (account):
  - Localizado em: `.env.configs/nodes/<nome-do-nó>/node.id`

### 1.4 - Compartilhar enodes e endereços dos nós

O enode é uma string que serve de identificador para o nó e que será utilizado neste roteiro.

- Sua formação é o que segue: `enode://<chave-pública-SEM-0x>@<ip>:<porta>`.
- Observe que o IP utilizado poderá ser diferente para o mesmo nó, pois haverá situações onde serão utilizados o IP externo e, outras, onde serão utilizados os IPs internos. Este roteiro chamará atenção para cada caso.

As instituições devem compartilhar num arquivo, os `enodes` e os `endereços (account)` de cada nó para que todas as instituições conheçam as informações de todos os nós da rede e possam conectar esses nós conforme a topologia da rede.

Para isso, deve-se usar um arquivo no seguinte repositório privado apenas para os participantes da rede: <https://github.com/RBBNet/participantes>. Este repositório deverá conter uma pasta que corresponde à rede que está sendo implantada. Esta pasta conterá alguns arquivos compartilhados pelo grupo, incluindo a lista de enodes.

Para exemplificar, considere que o nome da rede é atribuída à variável
rede, o que será útil em alguns momentos. Se a rede em implantação é a rede de laboratório, temos $rede=**"lab"**. Se é a rede piloto, $rede=**"piloto"**.

Assim, a lista de enodes ficará no arquivo em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/enodes.md`, com o formato sugerido abaixo. Observe que os enodes nessa lista usarão **sempre** os IPs **externos**. Para os writers, o IP e porta é necessário **apenas para os writers dos partícipes parceiros**. **Não é necessário** informar o IP e porta dos writers internos nessa lista.

| Membro    | Tipo de Nó    |Enode                                     |Account            |
|-----------|---------------|------------------------------------------|-------------------|
|BNDES      | Boot          |`enode://91c......3b@<IP address>:<port>` |                   |
|TCU        | Validator     |`enode://2b5......59@<IP address>:<port>` |0x5bcd....a4861984b|

### 1.5 - Compartilhar endereço de conta de administração

Cada instituição deve possuir um endereço de conta de administração. Para tanto, adicione um endereço de conta de administração na lista localizada em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/adminAddresses.md`. Conforme exemplo abaixo:

| Membro    | Endereço do administrador                  |
|-----------|--------------------------------------------|
|BNDES      | 0x38393851d6d26497de390b37b4eb0c1c20a5b0bc |
|DATAPREV   | 0xc78622f314453aeb349615bff240b6891cefd465 |
|TCU        | 0x8b708294671a61cb3af2626e45ec8ac228a03dea |

### 1.6 - Ajustar regras de firewall

Como antecipado, este trecho do roteiro diferencia entre os endereços IP externos e internos das instituições. A premissa é que as conexões entre os nós writer, boot e validator de uma instituição se dará por IPs internos e as conexões entre nós de diferentes instituições se dará por IPs externos.

O diagrama a seguir pode ser útil na compreensão dos próximos passos.

![Topologia da rede](https://i.imgur.com/BwHFxsf.png)

**As seguintes regras de firewall deverão ser configuradas:**  

- Todos os validators devem conseguir se conectar entre si. Por isso, para seus validators:
  - Permita conexão (inbound) no `IP_Externo:Porta` do seu validator a partir dos outros validators que integram a RBB.
  - Permita conexão (outbound) para os `IPs_Externos:Portas` dos outros validators que integram a RBB.
- Todos os boots devem conseguir se conectar entre si. Por isso, para seus boots:
  - Permita conexão (inbound) no `IP_Externo:Porta` do seu boot a partir dos outros boots que integram a RBB.
  - Permita conexão (outbound) para os `IPs_Externos:Portas` dos outros boots que integram a RBB.
- Todos os boots devem conseguir se conectar com os writers (**apenas dos partícipes parceiros**). Por isso, para seus boots:
  - Permita conexão (inbound) no `IP_Externo:Porta` do seu boot a partir dos writers (**apenas dos partícipes parceiros**) que integram a RBB.
  - Permita conexão (outbound) para os `IPs_Externos:Portas` dos writers (**apenas dos partícipes parceiros**) que integram a RBB.

## 2 - Atividades a serem executadas no início da rede pela instituição inicial

A instituição inicial desempenhará as primeiras atividades da rede. É ela quem levantará os primeiros nós antes de todos os outros e, em especial, é a responsável por implantar os **smart contracts** de permissionamento.

Caso você **não** seja a instituição inicial pule para a [seção 3](#3---atividades-a-serem-executadas-durante-a-entrada-de-cada-institui%C3%A7%C3%A3o-na-rede-com-exce%C3%A7%C3%A3o-da-primeira).

### 2.1 - Compartilhar genesis.json do nó validator

- **Apenas no nó validator**, execute o seguinte comando para criar um arquivo `genesis.json` com o validator definido no extradata:

  ```bash
  ./rbb-cli genesis create --validators validator
  
  ```

- Disponibilize o arquivo `genesis.json` do nó validator, localizado em `.env.configs/genesis.json`, com as outras instituições no seguinte caminho do repositório:

  `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json`

### 2.2 - Executar sub-roteiro "[Ajustar genesis e static-nodes](#41---ajustar-genesis-e-static-nodes)"

### 2.3 - Executar sub-roteiro "[Levantar os nós](#42---levantar-os-nós)"

### 2.4 - Implantar os smart contracts de permissionamento

#### 2.4.1 - Pré-requisito

- [Node.js](https://nodejs.org/en/download/)

#### 2.4.2 - Preparar o Deploy

- Execute os seguintes comandos:

  ```bash
  curl -#SL https://github.com/RBBNet/Permissionamento/releases/download/v1.0.0-backend-alpha/permissioningDeploy.tar.gz | tar xz
  cd permissioningDeploy
  
  ```

- Execute o seguinte comando para instalar as dependências:

  ```bash
  yarn install
  
  ```

  - ⚠️ Pode ser necessário também instalar o compilador offline do solidity caso você esteja em um ambiente corporativo: Se estiver no linux execute `yarn linuxcompiler`. Se estiver no Windows execute `yarn windowscompiler`. ⚠️


- Crie um arquivo `.env` e defina as variáveis de ambiente neste arquivo conforme template abaixo:

  ```.env
  NODE_INGRESS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000009999
  ACCOUNT_INGRESS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000008888
  BESU_NODE_PERM_ACCOUNT=627306090abaB3A6e1400e9345bC60c78a8BEf57
  BESU_NODE_PERM_KEY=c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3
  BESU_NODE_PERM_ENDPOINT=http://127.0.0.1:8545
  CHAIN_ID=648629
  INITIAL_ADMIN_ACCOUNTS=0x38393851d6d26497de390b37b4eb0c1c20a5b0bc,0xc78622f314453aeb349615bff240b6891cefd465,0x8b708294671a61cb3af2626e45ec8ac228a03dea
  INITIAL_ALLOWLISTED_ACCOUNTS=0x38393851d6d26497de390b37b4eb0c1c20a5b0bc,0xc78622f314453aeb349615bff240b6891cefd465,0x8b708294671a61cb3af2626e45ec8ac228a03dea
  INITIAL_ALLOWLISTED_NODES=enode://7ef6...d416|0|0x000000000000|Boot|BNDES,enode://d350...70d2|1|0x000000000000|Validator|BNDES,enode://971d...5c3c|2|0x000000000000|Writer|BNDES
  ```

  Em `BESU_NODE_PERM_ACCOUNT`, conforme o template, insira o endereço da conta a fazer o deploy e a ser a primeira conta de administração do permissionamento.

  Em `BESU_NODE_PERM_KEY`, insira a chave privada da conta mencionada acima conforme o template.
  > ⚠️ **Atenção!** Certifique-se de utilizar uma chave privada devidamente protegida.

  Em `BESU_NODE_PERM_ENDPOINT`, insira o endereço `IP_Interno:Porta` do seu validator conforme o template. Apenas nesse momento será utilizada a porta RPC do validator - e não do writer - para enviar transações.

  Em `CHAIN_ID`, insira a chain ID da rede conforme o template. A chain ID pode ser encontrada no arquivo `genesis.json`.

  Em `INITIAL_ADMIN_ACCOUNTS`, conforme o template, insira os endereços de conta de administração da lista localizada em: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/adminAddresses.md`.

  Em `INITIAL_ALLOWLISTED_ACCOUNTS`, conforme o template, insira os endereços de conta de administração da lista localizada em: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/adminAddresses.md`. As listas de administração e de conta (endereços de conta permitidos de enviarem transações na rede) são diferentes e independentes. Desta forma, faz-se necessário adicionar os endereços de conta de adminstração também nesta variável de ambiente para que seja possível enviar transações na rede.

  Em `INITIAL_ALLOWLISTED_NODES`, conforme o template, insira as informações de todos os nós da lista localizada em: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/enodes.md`. As informações de cada nó devem ser separadas por vírgula e devem ser inseridas da seguinte forma:
  
  ```.env
  enode://<chave-pública-SEM-0x>|<tipo-do-nó-(0: Boot, 1: Validator, 2: Writer, 3: WriterPartner, 4: ObserverBoot, 5: Other)>|<geohash-do-nó>|<nome-do-nó>|<nome-da-instituição>
  ```

#### 2.4.3 - Executar o Deploy

```bash
yarn truffle migrate --reset --network besu

```
#### 2.4.4 - Armazenando os endereços dos contratos.

Quando o truffle terminar de fazer o migrate, você verá no terminal os contratos e seus respectivos endereços, como mostra a imagem abaixo: 

![](https://i.imgur.com/kwI3nDK.png)

Armazene nesta tabela `https://github.com/RBBNet/participantes/blob/main/`**${rede}**`/Endere%C3%A7os%20dos%20Contratos.md` o endereço dos contratos **Admin**, **NodeRules** e **AccountRules**.

### 2.5 - Executar sub-roteiro "[Levantar DApp de permissionamento](#44---levantar-dapp-de-permissionamento)"

### 2.6 - Executar sub-roteiro "[Levantar monitoração](#45---levantar-monitora%C3%A7%C3%A3o)"

### 2.7 - Executar sub-roteiro "[Levantar block explorer](#46---levantar-block-explorer)"

## 3 - Atividades a serem executadas durante a entrada de cada instituição na rede (com exceção da primeira)

Após a instituição inicial começar a implantação da rede, as outras instituições entrarão uma após a outra. Os passos dessa seção serão executados a cada instituição que aderir à rede.

### 3.1 - Executar sub-roteiro "[Ajustar genesis e static-nodes](#41---ajustar-genesis-e-static-nodes)"

### 3.2 - Executar sub-roteiro "[Levantar os nós](#42---levantar-os-nós)"

### 3.3 - [SOMENTE VALIDATORS] Solicitar votação no validator

A votação de validadores é feita apenas por validadores. Caso possua um nó preparado para ser validator, mas ainda sem produzir blocos, avise às outras instituições - que possuem validadores produzindo blocos - para votarem no seu validator. Peça para executar o sub-roteiro "[Votar nos validadores](#43---votar-nos-validadores)".

### 3.4 - Executar sub-roteiro "[Levantar DApp de permissionamento](#44---levantar-dapp-de-permissionamento)"

### 3.5 - Executar sub-roteiro "[Levantar monitoração](#45---levantar-monitora%C3%A7%C3%A3o)"

### 3.6 - Executar sub-roteiro "[Levantar block explorer](#46---levantar-block-explorer)"

### 3.7 - Executar sub-roteiro "[Instanciar nós Boot de observer e Observer](#48---instanciar-n%C3%B3s-boot-de-observer-e-observer)"

---

## 4 - Sub-roteiros

### 4.1 - Ajustar genesis e static-nodes

As seguintes atividades serão executadas nesse sub-roteiro:

- Inclusão do arquivo genesis.json.
- Inclusão da lista de todos os boots (usando IPs externos) no genesis.json do boot.
- Criação de um arquivo static-nodes.json no validator com os validators das outras instituições (usando IPs externos) e com o boot da própria instituição (usando IP interno).
- Criação de um arquivo static-nodes.json no writer apenas com o boot da própria instituição (usando IP interno).

Os passos acima serão detalhados a seguir.

Os enodes que serão inseridos nos arquivos genesis.json e static-nodes.json podem ser obtidos no seguinte arquivo anteriormente compartilhado: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/enodes.md`.

#### 4.1.1 - Cópia do genesis.json para os nós

Para cada um dos nós (validator, boot e writer):

- Inclua em `.env.configs/`, o arquivo `genesis.json` localizado em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json`.

#### 4.1.2 - Ajustes no genesis.json do boot

- Inclua na seção apropriada (conforme modelo) do arquivo `.env.configs/genesis.json`, os enodes de todos os **outros** boots da rede.

  Modelo:

  ```json
  "discovery": {
    "bootnodes" : 
    [ 
      "enode://<chave-pública-SEM-0x>@<ip>:<porta>", 
      "enode://<chave-pública-SEM-0x>@<ip>:<porta>" 
    ]
  },
  ```

  O arquivo genesis.json do bootnode deve seguir conforme o exemplo abaixo:  
  ![Conteúdo exemplo do arquivo genesis.json](https://i.imgur.com/MPgJljO.png)

#### 4.1.3 - Ajustes nos static-nodes

Ajuste o arquivo `static-nodes.json` dos writers e validators da seguinte forma:

#### **Nós validators**

- Desabilite a descoberta de nós com o seguinte comando:

  ```bash
  ./rbb-cli config set nodes.validator.environment.BESU_DISCOVERY_ENABLED=false
  
  ```

- Nos **validators**, inclua no arquivo `volumes/validator/static-nodes.json` todos os enodes dos outros validators (usando **IPs externos**) e o enode do bootnode da própria instituição (usando **IP interno**).

  Modelo:

  ```json
  [ 
  "enode://<chave-pública-SEM-0x>@<ip-externo>:<porta>", 
  "enode://<chave-pública-SEM-0x>@<ip-externo>:<porta>",
  ...
  "enode://<chave-pública-SEM-0x>@<ip-interno>:<porta>"
  ]
  ```

#### **Nós writers**

- Desabilite a descoberta de nós com o seguinte comando:

  ```bash
  ./rbb-cli config set nodes.writer.environment.BESU_DISCOVERY_ENABLED=false
  
  ```

- Nos **writers**, inclua no arquivo `volumes/writer/static-nodes.json` o enode do boot interno usando o **IP interno**.

  Modelo:

  ```json
  [ 
  "enode://<chave-pública-SEM-0x>@<ip-interno>:<porta>"
  ]
  ```

### 4.2 - Levantar os nós

```bash
./rbb-cli config render-templates
docker-compose up -d

```

- Outros comandos úteis:

  - Utilize o seguinte comando para visualizar o log do nó:

    ```bash
    docker-compose logs -f
    
    ```

  - Utilize o seguinte comando para interromper o nó:

    ```bash
    docker-compose down
    
    ```

### 4.3 - Votar nos validadores

- Através de um validator, execute o seguinte comando **para votar em um outro validator**:

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["<endereço-do-validator-SEM-0x>",true], "id":1}' <JSON-RPC-endpoint-validator>:<porta>
```

O endereço dos validadores pode ser obtido em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/enodes.md` na coluna "Account".

### 4.4 - Levantar dApp de permissionamento

- Execute os seguintes comandos em um diretório que estará acessível pelo servidor web:

  ```bash
  curl -#SL https://github.com/RBBNet/dapp-permissionamento/archive/refs/tags/v1.0.1+2023-10-11.tar.gz | tar xz
  cd dapp-permissionamento-1.0.0-2023-10-10
  ```

- Siga o roteiro descrito no arquivo **README.md**.

### 4.5 - Levantar monitoração
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
    └── web-config.yml      # Arquivo de configuração para a interface web do Prometheus
```
#### 4.5.1 Habilitar as métricas no Besu:
> [!NOTE]
> As configurações a seguir devem ser realizadas em cada nó do Besu.

- Mapeie a porta padrão das métricas (9545) em uma porta do host. O exemplo abaixo usa o script *rbb-cli* para mapear a porta de métricas para o boot na porta 10002 do host. O comando correspondente (**nodes.<boot|validator|writer>.ports**) deverá ser realizado para os demais nós .
```
./rbb-cli config set nodes.boot.ports+=[\"10002:9545\"]
```

- No docker-compose.yml do nó Besu, as seguintes variáveis de ambiente devem estar configuradas:
```
BESU_METRICS_ENABLED: "true"
BESU_METRICS_HOST: "0.0.0.0"
BESU_HOST_ALLOWLIST: "*"        # Se a regra for mais restritiva, adicionar IP do Prometheus
```
  
- Reinicie o container Besu com as novas configurações:
```
docker-compose down
./rbb-cli config render-templates
docker-compose up -d
```

Para maiores detalhes sobre as métricas no Besu, consulte a [documentação](https://besu.hyperledger.org/public-networks/how-to/monitor/metrics).

#### 4.5.2 Disponibilizar as métricas para outras organizações
> [!NOTE]
> As configurações a seguir devem ser realizadas no servidor do Prometheus.

- Toda organização deverá ter uma configuração no Prometheus (arquivo prometheus.yml) que exporta as métricas com os seguintes requisitos:
```
- job_name: rbb
  labels:
    node: <boot|validator|writer|prometheus>, conforme o nó de origem da métrica. 
    organization: <nome da organização>
```
O arquivo de configuração do [repositório de monitoração](https://github.com/RBBNet/rbb-monitoracao) apresenta uma configuração (**job_name: rbb**) que atende a esses requisitos. Ele deverá ser alterado com os dados de cada organização.

- Preencher o arquivo **monitoring-endpoints.md** em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/monitoring-endpoints.md` com o valor para o label _organization_ da organização usado nas métricas, o IP e a porta do Prometheus que exporta as métricas.
> [!NOTE]
> As devidas liberações de firewall devem ser providenciadas.

#### 4.5.3 Capturar as métricas de outras organizações
A forma de capturar as métricas de outras organizações pode variar bastante. Por exemplo, elas podem ser capturadas com outro Prometheus ou diretamente por dashboards (Grafana, Zabix, etc.). No repositório de monitoração, é apresentada, como exemplo, uma forma de captura com o próprio Prometheus que exporta as métricas locais. Essa configuração pode ser verificada no arquivo prometheus.yml, *job_name: rbb_federado*. 

- Alterar os labels dos alvos (*targets*) de cada organização conforme abaixo:
```
- job_name: rbb-federado
  - targets: [<ip do prometheus alvo>]
    labels:
      organization: <nome da organização>
```
> [!NOTE]
> O job deve ser configurado com os alvos (*targets*) de outras organizações conforme o arquivo **monitoring-endpoints.md**.

#### 4.5.4 Levantar o Prometheus
- Uma vez alterado o arquivo prometheus.yml, levante o container do Prometheus:
```
docker-compose up -d
```
- Acesse a interface web do Prometheus e verifique o estado dos alvos (menu *Status -> Targets*), bem como algumas métricas (ex: no menu *Graph*, digite como expressão *ethereum_blockchain_height*).

### 4.6 - Levantar block explorer

#### Sirato Block Explorer

- Executar no boot node, no node de monitoramento, ou no node que irá executar o block explorer:

```bash
git clone https://github.com/web3labs/sirato-free.git

cd sirato-free/docker-compose

NODE_ENDPOINT=http://<ip-boot-node>:<porta-rpc> PORT=<porta-blockexplorer> docker-compose -f docker-compose.yml -f sirato-extensions/docker-compose-besu.yml up

```

- Acessar no browser remoto:

```bash
http://boot-node-ip:blockexplorer-port

```

### 4.7 - Levantar EthStats - Executar sub-roteiro "[Roteiro de instalação do EthStats](roteiro_monitoramento_ethstats.md)"

### 4.8 - Instanciar nós Boot de observer e Observer

O procedimento se encontra [neste link](https://github.com/RBBNet/rbb/blob/master/Como_instancia_boot-observer_observer.md).



