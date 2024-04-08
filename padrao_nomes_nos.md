# Padrão de Nomes dos Nós

A criação de nós para as redes de laboratório e piloto da RBB devem seguir o padrão especificado abaixo, a ser utilizado para fins de configuração, permissionamento e monitoração.

Os nomes dos nós devem ser definidos da seguinte forma: `<tipo_no><sequencial>`

Onde:
- `<tipo_no>` pode ser:
  - `boot`
  - `validator`
  - `writer`
  - `observer-boot`
- `<sequencial>` é um número inteiro, com dois dígitos, começando em `01`, para diferenciar diferentes nós de um mesmo tipo.

Exemplos de nomes válidos: `boot01`, `boot02`, `validator01`, `writer01`, `observer-boot01`


## Criação e Configuração de Nós

A criação e configuração de nós deve ser feita conforme o [roteiro de criação de uma rede](Roteiro_para_a_criacao_de_uma_rede.md), utilizando-se o utilitário [`rbb-cli`](guia_rbb-cli.md).

Sempre que for necessário informar o nome de um nó para o `rbb-cli`, deve-se utilizar o padrão definido acima.

Exemplos de comandos do `rbb-cli`:
```
./rbb-cli node create validator01
./rbb-cli config set nodes.validator01.environment.BESU_DISCOVERY_ENABLED=false
```

**Observação**: Caso o nome do nó contenha um hífen, ao se utilizar o comando `rbb-cli config set`, deve-se delimitar o nome entre `[\"` e `\"]`. Por exemplo:
```
./rbb-cli config set nodes.[\"observer-boot\"].ports+=[\"8545:8545\"]
```

## Permissionamento

Ao se se executar o *smart contract* de permissionamento de nós, o valor do parâmetro `name` da função `addEnode` também deve-se utilizar o padrão de nomenclatura.

Exemplo:
```
addEnode(enodeHigh, enodeLow, nodeType, geoHash, 'boot01', organization)
```

**Observação**: Atualmente o campo `geoHash` não está sendo usado e deve-se utilizar o valor fixo `'0x000000000000'`.