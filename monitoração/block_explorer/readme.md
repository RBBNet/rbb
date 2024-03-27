# Monitoração da Rede Blockchain Brasil

Block explorers são uma das ferramentas mais importantes no arsenal de um entusiasta em blockchain. Eles provêm uma interface online para procurar em uma blockchain, e permitem ao usuário recuperar informações sobre transações, endereços, blocos, taxas, e mais. Cada block explorer mostra informações sobre uma certa blockchain, e o tipo de informação incluída irá variar dependendo da arquitetura da rede.

Para aumentar a transparência da Rede Blockchain Brasil, foram anexados nós observadores (observer), aos quais cidadãos podem se conectar ao instanciar um nó de observer de usuário. Conectados a eles, por sua vez, podem estar os block explorers, permitindo o acompanhamento da rede em tempo real.

Ao se conectar com a rede, o nó observer baixa os blocos e valida todas as transações perante as regras definidas pelos smart contracts, assim como perante as regras de permissionamento definidas nesses contratos. Em outras palavras, um nó verifica as permissões ao importar blocos – ou seja, ele importa apenas blocos nos quais todas as transações são de remetentes autorizados (fonte: [documentação do Besu](https://besu.hyperledger.org/private-networks/concepts/permissioning/onchain)). Dessa forma, para que o observer consiga se conectar ao observer-boot (o nó público da rede), o smart contract “node rules” deverá estar desabilitado. 

> [!NOTE]
 O usuário final não precisa exatamente se preocupar com isso, afinal, o script para levantar um nó observer já configura permissões.

> [!IMPORTANT]
 Ainda assim, é incentivado que o usuário faça seu próprio script, mesmo que já exista um. É possível subir um nó observer e um block explorer a partir de uma aproximação “hands on”.

Todas as tecnologias utilizadas e códigos, salvo as configurações específicas para a RBB (como a pasta docker-compose do Blockscout), são produzidos por terceiros e podem ser conferidos nos links abaixo:

* [Besu](besu.hyperledger.org)
* [Blockscout](https://github.com/blockscout/blockscout)
* [Chainlens](https://github.com/web3labs/chainlens-free)

## Como subir um observer?

### Subindo um observer sem block explorer
Entre nesse [link](https://github.com/RBBNet/rbb/blob/master/monitora%C3%A7%C3%A3o/block_explorer/blockscout/observer_user.sh), faça o download do arquivo e pare na linha 99 - dessa forma, o script não irá baixar o block explorer, e apenas o observer será levantado. Tenha em mente que ele estará rodando em localhost:8545.

### Subindo um observer com Blockscout
Entre nesse [link](https://github.com/RBBNet/rbb/blob/master/monitora%C3%A7%C3%A3o/block_explorer/blockscout/observer_user.sh), faça o download do arquivo e execute normalmente.

Tutorial: disponível [aqui](https://github.com/RBBNet/rbb/blob/master/monitora%C3%A7%C3%A3o/block_explorer/blockscout/readme.md)

### Subindo um observer com Chainlens
Entre nesse [link](https://github.com/RBBNet/rbb/blob/master/monitora%C3%A7%C3%A3o/block_explorer/chainlens-free/observer_user.sh), faça o download do arquivo e execute normalmente.

Tutorial: disponível [aqui](https://github.com/RBBNet/rbb/blob/master/monitora%C3%A7%C3%A3o/block_explorer/chainlens-free/readme.md)

## Qual usar?

Neste diretório, se encontram duas opções de block explorer: o Chainlens e o Blockscout. Nenhuma delas é favorecida em relação à outra, de forma que o usuário pode verificar e analisar ambas. 

> [!NOTE]
O usuário não é obrigado a ficar com nenhuma das duas alternativas, de forma que pode escolher um entre as dezenas de block explorers que existem no mercado.

![image](https://github.com/RBBNet/rbb/assets/111009073/9acb9754-a5d7-4913-9ebc-0c418ee0d0c1)


![image](https://github.com/RBBNet/rbb/assets/111009073/867eccce-92ed-4082-a795-54045ec08d4c)


