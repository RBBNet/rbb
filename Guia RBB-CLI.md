Guia dos comandos da Interface de Linha de Comando (CLI) da RBB, acessível na lxc21 por ./rbb-cli.

## config
### set
Altera o infra.json no start-network. 
Sintaxe do comando mais utilizado:
```
./rbb-cli config set nodes.<boot, writer, validator>.<ports+=[\"<número-porta-VM:número-porta-nó>"\], address =\"<IP-externo-nó>:número-porta-VM\">
```

Visto em:
* Alteração de variável de ambiente do Besu especificamente de um nó:
```
./rbb-cli config set nodes.<nome_do_nó>.environment.<VARIÁVEL_DE_AMBIENTE_DO_BESU>=<VALOR_DA_VARIÁVEL>
```
É possível obter as variáveis de ambiente do Besu aqui [nesse link](https://besu.hyperledger.org/stable/public-networks/reference/cli/options).

* Definição da porta da VM pela qual serão feitas chamadas RPC para os nós:
```
./rbb-cli config set nodes.validator.ports+=[\"10001:8545\"]
```
* Desabilitando a descoberta de nós:
```
./rbb-cli config set nodes.validator.environment.BESU_DISCOVERY_ENABLED=false
```

### dump
Mostra as configurações (a chave pública, endereço e outras informações sobre os nós). 
Sintaxe:
```
./rbb-cli config dump
```

### render-templates
Renderiza os templates .hbs. Utilizar por último, ao iniciar os nós.
```
./rbb-cli config render-templates
```

## node
Gera as chaves públicas e privadas e os endereços dos nós, criando a pasta "volumes" no processo.
Sintaxe:

```
./rbb-cli node create <nó>
```

É possível criar mais de um nó igual, como em ``` ./rbb-cli node create validator1, validator2, validator3, validator4 ```. 
Note que os nós *não* podem ter o mesmo nome, pois isso gera conflito. 
Para criar de uma única vez nós diferentes, usa-se a separação por vírgula, como em ``` ./rbb-cli node create validator, boot, writer ```

## genesis
Cria o arquivo genesis.json. Chamando sem "adição", como em ``` ./rbb-cli genesis create ```, os nós não são definidos no extradata. Com "adição",
é necessário fazer isso apenas para o validator - ``` ./rbb-cli genesis create --validators validator ```. 
Sintaxe:
```
./rbb-cli genesis create --<validators, boots> <nome-do-nó, nome:IP:porta>
```

Note que ao pôr mais parâmetros no genesis create, eles não podem ter espaços entre si. Exemplo:

```
./rbb-cli genesis create --validators validator1,validator2,validator3,validator4
```
