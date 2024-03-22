# Guia de Comandos do utilitário rbb-cli

Este documento é um guia para o utilitário de interface de linha de comando (CLI) da RBB, o `rbb-cli`. Este utilitário permite a configuração de nós no padrão da RBB, para posterior execução em contêineres Docker.

A configuração dos nós é feita a partir de comandos que geram arquivos e preenchem *templates* para que diferentes tipos de nós Besu possam ser configurados e posteriormente utilizados nos contêineres.

Os *templates* utilizados são:
- `docker-compose.yml.hbs`: Utilizado para configuração do Docker Compose.
- `templates/genesis.json.hbs`: Utilizado para a geração de arquivo genesis dos nós.
- `.env.configs/static-nodes-local-boot.json.hbs`: Utilizado para configuração estática de conectividade entre nós.
- `.env.configs/static-nodes-validators.json.hbs`: Utilizado para configuração estática de conectividade entre nós.
- `.env.configs/static-nodes-validators-and-local-boot.json.hbs`: Utilizado para configuração estática de conectividade entre nós.


## Criação de Nós

A criação de nós é feita com o comando `node create`. Esse comando gera a configuração inicial de um nó, gerando as chaves pública e privada e o endereço do nó e armazenando-as em uma pasta correspondente `.env.configs/<no>`.

Sintaxe:
```
./rbb-cli node create <no>
```

Onde:
- `<no>` é o nome do nó a ser criado. Exemplos: `validator`, `boot`, `writer`, `observer-boot`

Exemplo:
```
./rbb-cli node create validator
```

É possível criar mais de um nó de uma única vez, informando-se diferentes nomes separados por vírgula. Exemplo:
```
./rbb-cli node create boot,writer
``` 


## Configuração dos nós

A configuração dos nós é feita com o comando `config`. As seguintes opções podem ser usadas com esse comando:

- `set`
- `dump`
- `render-templates`

Os parâmetros de um nó são, inicialmente, configurados com o comando `config set` e armazenados, de forma temporária, em um arquivo chamado `infra.json`. Posteriormente, os parâmetros são aplicados aos nós com o comando `render-templates`, quando os valores configurados são substituídos em *templates* para geração dos arquivos efetivos de configuração dos nós.

A configuração definida para os nós pode ser feita com o comando `config dump`.

Ainda, caso se esteja criando uma nova rede ("do zero"), será necessário também criar um arquivo genesis, utilizando o comando `genesis create`.


### Configurando parâmetros

A definição de valores de parâmetros e variáveis de ambiente para um nó pode ser feita com o comando `config set`.

Sintaxe:
```
./rbb-cli config set nodes.<no>.<parametro>=<valor>
./rbb-cli config set nodes.<no>.environment.<variavel>=<valor>
```

Onde:
- `<no>` é o nome do nó a ser configurado, conforme foi criado com o comando `node create`.
- `<parametro>` é o nome do parâmetro a ser configurado. Exemplos: `ports`, `address`
- `<variavel>` é o nome da variável de ambiente a ser configurada. Exemplos: `BESU_DISCOVERY_ENABLED`
- `<valor>` é o valor a ser configurado para o parâmetro ou variável de ambiente. Exemplos: `false`, `[\"10001:8545\"]`, `\"123.123.123.123:10305\"`

**Observação**: Para a definição do valor do parâmetro ou variável de ambiente, pode-se usar o operador `=`, para definir um novo valor, ou o operador `+=`, para acrescentar o novo valor informado a um valor já definido previamente.

Exemplos:
```
./rbb-cli config set nodes.validator.ports+=[\"10001:8545\"]
./rbb-cli config set nodes.validator.address=\"123.123.123.123:10303\"
./rbb-cli config set nodes.validator.environment.BESU_DISCOVERY_ENABLED=false
```

Parâmetros comumente utilizados:
- `nodes.<no>.ports+=[\"<porta_host>:<porta_interna_conteiner>\"]`: Definição da porta pela qual serão feitas chamadas RPC para os nós.
- `nodes.<no>.address=[\"<ip_externo>:<porta_externa>\"]`: Definição do IP e da porta externos pelos quais serão recebidas chamadas de discovery para os nós.

Variáveis comumente utilizadas:
- `nodes.<no>.environment.BESU_DISCOVERY_ENABLED=<true|false>`: Liga ou desliga a descoberta de nós no Besu.

**Observação**: O Besu permite que seus [parâmetros sejam configurados a partir de variáveis de ambiente](https://besu.hyperledger.org/stable/public-networks/reference/cli/options#specify-options). Para isso, um parâmetro como nome `parametro-configuracao-qualquer` pode ser configurado através de uma varíavel de ambiente correspondente com o nome `BESU_PARAMETRO_CONFIGURACAO_QUALQUER`. É possível conhecer os parâmeros de configuração do Besu na [página de documentação para redes públicas](https://besu.hyperledger.org/stable/public-networks/reference/cli/options) e na [página de documentação para redes privadas](https://besu.hyperledger.org/stable/private-networks/reference/cli/options)

Caso se deseje testar a definição de um parâmetro sem que essa alteração seja efetivamente gravada, é possível usar a opção `--dry-run`:
```
./rbb-cli config set --dry-run nodes.validator.address=\"123.123.123.123:10303\"
```


### Visualizando parâmetros

Para consultar as configurações feitas para todos os nós configurados, deve-se utilizar o comando:
```
./rbb-cli config dump
```

Serão listadas, em formato JSON, para cada nó:
- Nome
- Identificador
- Chave pública
- Demais parâmetros e variáveis de ambiente configurados


### Configuração incial da blockchain - Genesis

Caso a configuração dos nós esteja sendo feita para uma rede já existente, um arquivo genesis (`genesis.json`) será fornecido e o mesmo deverá ser copiado para a pasta `.env.config`.

Entretanto, caso a configuração esteja sendo feito para uma nova rede, um novo arquivo genesis deverá ser criado com o comando `genesis create`.

Sintaxe:
```
./rbb-cli genesis create [--validator|--validators|-v <no>] [--boot|--boots|-b <no|endereco>]
```

Onde:
- Para definição de nós validadores, a serem incluídos na propriedade `extradata` do arquivo genesis, é possível usar qualquer das seguintes opções: `--validator`, `--validators` ou `-v`.
- `<no>` é o nome do nó, ou lista de nós separados por vírgula, a serem configurados como validators da nova rede. Exemplos: `validator`, `validator1,validator2,validator3`
- Para a definião de nós boot, a serem incluídos na configuração de `discovery` do arquivo genesis, é possível usar qualquer das seguintes opções: `--boot`, `--boots` ou `-b`.
- `<no|endereco>` é o nome do nó ou endereço enode (`chave_publica_sem0x:ip:porta`). Também pode ser informada uma lista de nós ou endereços separados por vírgula. Exemplos: `boot1`, `ec254664b4d1ca7b587c70943a5d10a2d2fb74af0b501dac6c07de53ebc9f1465023e7533d215082a3e83f2fa5a63aba509770960704012bed5c65efd515cd40:100.100.100.100:30303`

Exemplo:
```
./rbb-cli genesis create --validators validator1,validator2 --boots boot1,boot2,boot3
```


### Aplicação das configurações aos nós

As configurações realizadas com os comandos `config set` ficam inicialmente guardadas no arquivo `infra.json`, em formato JSON de estrutura desconhecida pelo Besu. Para que essas configurações possam ser transportadas para os arquivos de configuração do Besu e efetivamente aplicadas aos nós, é necessário utilizar o comando:
```
./rbb-cli config render-templates
```


## Execução de Nós

Uma vez que todos nós foram criados e configurados, os mesmos podem ser iniciados através do Docker Compose:
```
docker-compose up -d
```


### Execução em um mesmo servidor ou em servidores diferentes

Através do `rbb-cli` é possível configurar vários nós de uma só vez, para sejam iniciados e executados diretamente de um mesmo servidor (ou máquina virtual). Desta forma, o Docker Compose orquestrará a inicialização de vários contêineres de uma só vez. Esta abordagem é útil para a montagem de redes de teste locais, por exemplo.

Porém, o `rbb-cli` também é flexível para possibilitar que cada nó seja configurado em um servidor (ou máquina virtual) diferente. Nesse caso, o `rbb-cli` deverá ser executado em cada um dos servidores desejados, para que cada nó seja configurado individualmente. Desta forma, ao ser iniciado em cada servidor, o Docker Compose inicializará um único contêiner de cada vez. Esta abordagem é a recomendada para a execução de nós das redes de laboratório e piloto.


### Comandos úteis do Docker Compose


#### Visualização de logs
```
docker-compose logs -f
```


#### Interromper a execução
```
docker-compose down
```
