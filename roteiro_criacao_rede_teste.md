
# Roteiro para levantar uma rede de testes (toy)

Este roteiro tem como objetivo levantar uma rede para testes compatível com a RBB. Além disso, este roteiro assume que os nós serão iniciados em uma mesma máquina virtual (Virtual Machine - VM).

## 1 - Preparação

### 1.1 - Pré-requisitos

- [Docker](https://www.docker.com/products/docker-desktop/)
- Git

### 1.2 - Baixar o repositório `start-network`

- Execute os seguintes comandos:

  ```bash
  git clone https://github.com/RBBNet/start-network.git
  cd start-network
  
  ```

Daqui para frente, considere que todos os comandos são executados dentro do diretório start-network.

### 1.3 - Preparar arquivos

Execute o comando/script abaixo para gerar as chaves públicas e privadas e os endereços dos nós validator, boot e writer. Exemplo:

```bash
./rbb-cli node create validator, boot, writer

```

- Execute os comandos abaixo para definir a porta da VM pela qual serão feitas chamadas RPC para os nós. Na primeira linha do exemplo abaixo é mapeado a porta 10001 da VM (host) para a porta 8545 do nó validator (container), a porta 8545 do nó é a porta padrão para chamadas RPC via HTTP:

    ```bash
    ./rbb-cli config set nodes.validator.ports+=[\"10001:8545\"]
    ./rbb-cli config set nodes.boot.ports+=[\"10002:8545\"]
    ./rbb-cli config set nodes.writer.ports+=[\"10003:8545\"]
    
    ```

Após a execução dos comandos acima os seguintes itens serão gerados:

- Par de chaves pública/privada:
  - Caminho da chave privada: `.env.configs/nodes/<nome-do-nó>/key`
  - Caminho da chave pública: `.env.configs/nodes/<nome-do-nó>/key.pub`
- Endereço do nó (account):
  - Localizado em: `.env.configs/nodes/<nome-do-nó>/node.id`

A chave pública, endereço e outras informações sobre os nós podem ser obtidas através do seguinte comando:

```bash
./rbb-cli config dump

```

### 1.4 - Informações úteis

- Enode

  O enode é uma string que serve de identificador para o nó e que será utilizado neste roteiro.

  Sua formação é o que segue: `enode://<chave-pública-SEM-0x>@<ip>:<porta>`.

- Variáveis de ambiente do Besu
  
  As variáveis de ambiente do Besu para **todos os nós** podem ser alteradas no arquivo `docker-compose.yml.hbs`.
  Para alterar a variável de ambiente do Besu **especificamente de um nó**, execute o comando abaixo:

  ```bash
  ./rbb-cli config set nodes.<nome_do_nó>.environment.<VARIÁVEL_DE_AMBIENTE_DO_BESU>=<VALOR_DA_VARIÁVEL>

  ```

- Topologia

  A topologia da RBB está de acordo com o diagrama abaixo e pode ser útil na compreensão dos próximos passos.

  ![Topologia da rede](https://i.imgur.com/BwHFxsf.png)

## 2 - Ajustes do arquivo genesis e static-nodes

### 2.1 - Criar genesis.json

- Execute o seguinte comando para criar um arquivo `genesis.json` com o validator definido no extradata:

  ```bash
  ./rbb-cli genesis create --validators validator
  
  ```

### 2.2 - Ajustar static-nodes

As seguintes atividades serão executadas nesse sub-roteiro:

- Criação de um arquivo static-nodes.json no validator apenas com o boot.
- Criação de um arquivo static-nodes.json no writer apenas com o boot.

Os passos acima serão detalhados a seguir.

#### **Nó validator**

- Desabilite a descoberta de nós com o seguinte comando:

  ```bash
  ./rbb-cli config set nodes.validator.environment.BESU_DISCOVERY_ENABLED=false
  
  ```

- No **validator**, crie e inclua no arquivo `volumes/validator/static-nodes.json` o enode do boot.

  Modelo:

  ```json
  [
  "enode://<chave-pública-SEM-0x>@boot:30303"
  ]
  ```

#### **Nó writer**

- Desabilite a descoberta de nós com o seguinte comando:

  ```bash
  ./rbb-cli config set nodes.writer.environment.BESU_DISCOVERY_ENABLED=false
  
  ```

- No **writer**, crie e inclua no arquivo `volumes/writer/static-nodes.json` o enode do boot.

  Modelo:

  ```json
  [ 
  "enode://<chave-pública-SEM-0x>@boot:30303"
  ]
  ```

## 3 - Iniciar os nós

Caso o permissionamento venha a ser utilizado, inicie apenas o validator neste primeiro momento para realizar o deploy dos smart contracts de permissionamento: 

```bash
./rbb-cli config render-templates
docker-compose up -d validator

```

Caso contrário, execute os seguintes comandos:

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

## 4 - [OPCIONAL] Implantar os smart contracts de permissionamento

### 4.1 - Pré-requisito

- [Node.js](https://nodejs.org/en/download/)

### 4.2 - Preparar o Deploy

- Execute os seguintes comandos:

  ```bash
  git clone https://github.com/RBBNet/Permissionamento.git
  cd Permissionamento/gen01
  
  ```

- Execute o seguinte comando para instalar as dependências:

  ```bash
  yarn install
  
  ```

- Crie um arquivo `.env` e defina as variáveis de ambiente neste arquivo conforme template abaixo:

  ```.env
  NODE_INGRESS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000009999
  ACCOUNT_INGRESS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000008888
  BESU_NODE_PERM_ACCOUNT=627306090abaB3A6e1400e9345bC60c78a8BEf57
  BESU_NODE_PERM_KEY=c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3
  BESU_NODE_PERM_ENDPOINT=http://localhost:8545
  CHAIN_ID=648629
  INITIAL_ALLOWLISTED_NODES=enode://7ef6...d416|0|0x000000000000|Boot|BNDES,enode://d350...70d2|1|0x000000000000|Validator|BNDES,enode://971d...5c3c|2|0x000000000000|Writer|BNDES
  ```

  Em `BESU_NODE_PERM_ACCOUNT`, conforme o template, insira o endereço da conta a fazer o deploy e a ser a primeira conta admin do permissionamento. Por ser este um roteiro somente para testes, o endereço contido no template poderá ser utilizado.

  Em `BESU_NODE_PERM_KEY`, insira a chave privada da conta mencionada acima conforme o template. Por ser este um roteiro somente para testes, a chave privada contida no template poderá ser utilizada.
  > ⚠️ **Atenção!** Não utilize a chave privada do template em ambiente de **produção**.

  Em `BESU_NODE_PERM_ENDPOINT`, insira o endereço `IP:Porta` do seu validator (utilize o IP do container, execute ```docker ps``` para localizar o id do container do validator e, em seguida, ```docker inspect <container-id> | grep "IPAddress"``` para obter o IP do container do validator ) conforme o template. Apenas nesse momento será utilizada a porta RPC do validator - e não do writer - para enviar transações.

  Em `CHAIN_ID`, insira a chain ID da rede conforme o template. A chain ID pode ser encontrada no arquivo `genesis.json`.

  Em `INITIAL_ALLOWLISTED_NODES`, conforme o template, insira as informações dos nós validator, boot e writer. As informações de cada nó devem ser separadas por vírgula e devem ser inseridas da seguinte forma:

  ```.env
  enode://<chave-pública-SEM-0x>|<tipo-do-nó-(0: Boot, 1: Validator, 2: Writer, 3: WriterPartner, 4: ObserverBoot, 5: Other)>|<geohash-do-nó>|<nome-do-nó>|<nome-da-instituição>
  ```

### 4.3 - Executar o Deploy

```bash
yarn deploy --network besu

```

### 4.4 - Iniciar os outros nós

```bash
docker-compose up -d boot writer

```

Caso os nós não se conectem, reinicie o validator:

```bash
docker-compose restart validator

```

## 5 - Levantar block explorer

#### Sirato Block Explorer:

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
