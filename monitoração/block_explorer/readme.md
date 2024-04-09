# Acesso aos dados da Rede Blockchain Brasil

*Block explorers* são ferramentas importantes no arsenal de um entusiasta em blockchain. Eles provêm uma interface online para realizar pesquisas em uma blockchain e permitem ao usuário recuperar informações sobre transações, endereços, blocos, taxas e mais. Cada *block explorer* mostra informações sobre uma certa blockchain, e o tipo de informação incluída irá variar dependendo da arquitetura da rede.

Para aumentar a transparência da Rede Blockchain Brasil, e permitir acesso a seus dados, foram previstos em sua topologia nós conectores para observação da rede (*observer boots*), aos quais cidadãos podem se conectar ao instanciar um nó observador (*observer*) local em seu próprio computador. Conectados a estes nós *observers*, por sua vez, podem estar os *block explorers*, permitindo o acompanhamento da rede em tempo real.

Ao se conectar com a rede, o nó *observer* baixa os blocos e valida todas as transações perante as regras definidas pelos *smart contracts*, assim como perante as regras de permissionamento definidas nesses contratos. Em outras palavras, um nó verifica as permissões ao importar blocos – ou seja, ele importa apenas blocos nos quais todas as transações são de remetentes autorizados (fonte: [documentação do Besu](https://besu.hyperledger.org/private-networks/concepts/permissioning/onchain)). Dessa forma, para que o *observer* consiga se conectar a um *observer-boot* (um dos nós públicos da rede), o *smart contract* "node rules" deverá estar desabilitado. 

> [!NOTE]
 O usuário final não precisa se preocupar com isso. O script para levantar um nó *observer*, disponível a seguir, já configura as permissões corretamente.

> [!IMPORTANT]
 Ainda assim, é incentivado que o usuário faça seu próprio script. É possível subir um nó *observer* e um *block explorer* de forma independente.

Todas as tecnologias e códigos utilizadas no script fornecido a seguir, salvo as configurações específicas para a RBB (como a pasta `docker-compose` do Blockscout), são produzidos por terceiros e podem ser conferidos nos links abaixo:

* [Besu](besu.hyperledger.org)
* [Blockscout](https://github.com/blockscout/blockscout)
* [Chainlens](https://github.com/web3labs/chainlens-free)

## Recursos mínimos necessários
Redes blockchain podem variar em tamanhos e requisitos. Antes de subir um nó *observer* com *block explorer*, verifique se você atinge as seguintes condições mínimas:

### Para o Blockscout
* CPU: 6 core, 12 thread
* RAM: 16 GB
* Disco: 80 GB

⚠️ Pode ser que o Blockscout consiga funcionar em máquinas mais modestas. Caso a máquina em questão não consiga se aproximar dos requisitos mínimos, é interessante utilizar o Chainlens, uma alternativa mais leve.

### Para o Chainlens
* CPU: 2 core, 4 thread
* RAM: 4 GB
* Disco: 80 GB

## Softwares necessários
Além dos requisitos de hardware, os seguintes softwares são necessários:
* Git
* Docker v20.10+
* Docker compose v2.24+

> [!NOTE]
> Notamos que as as versões do compose 2.24.7, 2.25.0 e 2.26.0 **não se mostraram compatíveis** com o Blockscout a princípio. E a versão 1.x.x do docker-compose **não é suportada**.

👉 Para implantações no Windows, deve ser instalado o WSL2 (caso não esteja instalado) e, em seguida, o Docker.

> [!IMPORTANT]
 A data e hora do sistema devem estar devidamente atualizadas para que seja possível a sincronização de blocos.

## Opções de *block explorer*

Este roteiro considera duas opções de *block explorer*: o Chainlens e o Blockscout. Nenhuma delas é favorecida em relação à outra, de forma que o usuário pode verificar e analisar ambas. 

> [!NOTE]
O usuário não é obrigado a ficar com qualquer das duas alternativas e, caso deseje, pode escolher outro entre as dezenas de *block explorers* que existem no mercado para explorar os dados da RBB. Este roteiro, entretanto, não abordará outras alternativas.

![1](https://github.com/RBBNet/rbb/assets/111009073/cf2c7f38-535c-46d6-9777-ab580d4c2d94)
![2](https://github.com/RBBNet/rbb/assets/111009073/4ed10505-c3b2-4d09-8a84-537479457397)

## Iniciando um nó *observer* e um *block explorer*

Este roteiro supõe que o usuário possui uma máquina Linux ou o WSL previamente configurado.
Primeiro, faça o download do script referenciado no comando abaixo e conceda as permissões necessárias para sua execução:

```bash
curl -#sLO https://raw.githubusercontent.com/RBBNet/rbb/master/monitora%C3%A7%C3%A3o/block_explorer/rbb-observer
chmod +x rbb-observer
```

O script pode ser utilizado de mais de uma maneira, conforme descrito nas seções a abaixo, a depender das ferramentas que se deseja executar.

### Opção 1 - Iniciar *observer* sem *block explorer*

Para iniciar apenas o nó *observer*, **sem** um *block explorer* "acoplado", digite o seguinte comando:

```bash
./rbb-observer
```

### Opção 2 - Iniciar *observer* + Blockscout

Para iniciar o nó *observer*, com o Blockscout "acoplado", digite o seguinte comando:

```bash
./rbb-observer -b
```

Será possível acompanhar as transações e visualização dos blocos acessando a URL informada ao final da instalação, usando um navegador web.

### Opção 3 - Iniciar *observer* + Chainlens

Para iniciar o nó *observer*, com o Chainlens "acoplado", digite o seguinte comando:

```bash
./rbb-observer -c
```

Será possível acompanhar as transações e visualização dos blocos acessando o endereço *http://localhost:5001* usando um navegador web.

## Utilização do *block explorer*

Ao acessar o dashboard do *block explorer* (Blockscout ou Chainlens), será possível observar os blocos sendo baixados e indexados. Nesta etapa inicial, é esperado que a sincronização com a RBB leve um tempo considerável para ocorrer, até que todos os blocos possam ser recebidos. O Chainlens tem a vantagem de mostrar ao usuário a percentagem de sincronização. 

### Verificação de contratos - Apenas no Blockscout

Após subir o Blockscout, é necessário esperar até que todos os blocos estejam indexados. Esse processo é diferente de *baixar* os blocos, e pode demorar de horas a dias. Quando isso ocorrer, será possível usar os serviços do Blockscout, destacando-se o de verificação de contratos. A verificação de um smart contract envolve a submissão de seu código fonte para garantir que o *bytecode* que se encontra na blockchain corresponde ao código fonte fornecido ao usuário.

Os contratos do permissionamento utilizado na RBB se encontram [nesse link](https://github.com/RBBNet/Permissionamento/tree/main/contracts).

| Contrato | Endereço |
|----------|----------|
|Admin|0xe6e9af633D886CB83d43C1Af10D5F7080c824a76|
|NodeRules|0xcE74Df8d10Bd8b81395A9b7BEfE09b2bBC868dfb|
|AccountRules|0x8f568E67317457d4847813a9cc0d2E074c74e759|

Para efetivamente verificar os contratos, entre no endereço do Blockscout disponibilizado pelo script e clique no seguinte botão:
![image](https://github.com/RBBNet/rbb/assets/111009073/8261d83c-42b7-474f-9106-094817f7f78f)

Ao clicar no botão, aparecerá a tela de verificação de *smart contracts*. Alguns argumentos serão pedidos, como o endereço (incluindo 0x[...]), a licença e o tipo de verificação. A licença, no caso da RBB será `None`, e o tipo de verificação é à escolha do usuário. Caso seja necessário utilizar vários arquivos para a verificação, deve-se utilizar a opção `Multi-part form files`.

![image](https://github.com/RBBNet/rbb/assets/111009073/d264e32e-e81a-4080-82a6-df2e29e3860b)

A versão do compilador deve ser `0.5.9+commit.e560f70d`. A versão da EVM é a default, mas, caso dê erro, tente `petersburg`. Otimização desabilitada - sabe-se que ela muda o bytecode do código, o que impossibilita a verificação. Por fim, adicione na caixa pontilhada os arquivos dos smart contracts.

⚠️ Se um contrato importar outro, disponibilize também o importado. Exemplo: contrato A importa contrato B e C, então na hora de verificar o contrato A, é necessário enviar B e C junto para a verificação.

Por fim, clique em "verify & publish".

![image](https://github.com/RBBNet/rbb/assets/111009073/c5645498-c58a-4c89-ab39-7deb76f1230c)

## Consulta aos logs do nó *observer*

Caso tenha interesse em observar o fluxo de sincronização de blocos do *observer* ou mesmo investigar problemas, utilize o seguinte comando:

```bash
./rbb-observer --logs
```

## Desinstalação

Para remover completamente o nó *observer* e *block explorer* instalados, digite:

```bash
./rbb-observer -r
```

Este comando removerá todos os arquivos e dados baixados, incluindo dados de blocos da blockchain, e removerá quaisquer imagens Docker criadas.

## Erros

### Nó *observer* não subiu

Verifique os logs do *observer*, conforme comando informado acima.

### Blockscout não subiu

Verifique os logs de erro com o comando `docker compose logs -f` a partir da pasta `./chainlens-free/docker-compose` criada pelo script. Caso não saiba como proceder, procure informações e ajuda na [comunidade do Blockscout](https://discord.gg/blockscout).

### O carregamento de blocos no Chainlens não sai de 0%

Talvez o *observer* não tenha conseguido se conectar com o nó de sincronização. Reinicie o nó e veja se volta a sincronizar:

```
./rbb-observer --restart
```

## Ler também

👉 [Documentação do Blockscout](https://docs.blockscout.com/for-users/overviews)

👉 [Documentação do Chainlens](https://docs.chainlens.com/)
