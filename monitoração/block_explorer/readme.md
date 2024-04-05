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

## Recursos mínimos necessários
Redes blockchain podem variar em tamanhos e requisitos. Antes de subir um observer com block explorer, verifique se você atinge as seguintes condições mínimas:

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
Além dos requisitos de hardware, os seguintes softwares são de vital importância:
* Git
* Docker v20.10+
* Docker compose v2.24+

> [!NOTE]
> Notamos que as as versões do compose 2.24.7, 2.25.0 e 2.26.0 não se mostraram compatíveis com o Blockscout a princípio. A versão 1.x.x do docker-compose não é suportada.

👉 Para implantações no Windows, deve ser instalado o WSL2 (caso não esteja instalado) e, em seguida, o Docker. A data e hora do sistema deve estar devidamente atualizada para que seja possível a sincronização de blocos.

## Passo 1 - escolhendo um block explorer (opcional)
Neste diretório, se encontram duas opções de block explorer: o Chainlens e o Blockscout. Nenhuma delas é favorecida em relação à outra, de forma que o usuário pode verificar e analisar ambas. 

> [!NOTE]
O usuário não é obrigado a ficar com nenhuma das duas alternativas, de forma que pode escolher um entre as dezenas de block explorers que existem no mercado.

![1](https://github.com/RBBNet/rbb/assets/111009073/cf2c7f38-535c-46d6-9777-ab580d4c2d94)
![2](https://github.com/RBBNet/rbb/assets/111009073/4ed10505-c3b2-4d09-8a84-537479457397)

## Passo 2 - subindo um observer
Esse roteiro supõe que o usuário possui uma máquina Linux ou o WSL previamente configurado.
Primeiro, faça o download do script e conceda as permissões necessárias:

```bash
curl -#sLO https://raw.githubusercontent.com/RBBNet/rbb/master/monitora%C3%A7%C3%A3o/block_explorer/rbb-observer
chmod +x rbb-observer

```
### Observer sem block explorer
Para subir o observer sem um block explorer "acoplado", digite o seguinte comando:

```bash
./rbb-observer
```

### Observer + Blockscout
```bash
./rbb-observer -b
```

Ao término da instalação, você poderá acompanhar as transações e visualização dos blocos acessando a URL informada ao final da instalação. Acesse utilizando um navegador como Chrome, Firefox, Edge ou demais navegadores.

### Observer + Chainlens
```bash
./rbb-observer -c
```

Ao término da instalação, você poderá acompanhar as transações e visualização dos blocos acessando *http://localhost:5001* usando Chrome, Firefox, Edge ou demais navegadores.

## Passo 3 - utilização

Ao acessar o dashboard, você já poderá observar os blocos sendo baixados e indexados. Nesta etapa inicial, é esperado que a sincronização com a RBB leve um tempo considerável para ocorrer, até que todos os blocos possam ser recebidos. O Chainlens tem a vantagem de mostrar ao usuário a percentagem de sincronização. 

### Verificação de contratos - exclusivo do Blockscout

Após subir o Blockscout, é necessário esperar até que todos os blocos estejam indexados. Quando isso ocorrer, você poderá usar os serviços do Blockscout, destacando-se o de verificação de contratos. A verificação de um smart contract envolve a submissão de seu código fonte para garantir que o bytecode que se encontra na blockchain corresponde ao código fonte fornecido ao usuário.

Os contratos do permissionamento utilizado na Rede Blockchain Brasil se encontram [nesse link](https://github.com/RBBNet/Permissionamento/tree/main/contracts).

| Contrato | Endereço |
|----------|----------|
|Admin|0xe6e9af633D886CB83d43C1Af10D5F7080c824a76|
|NodeRules|0xcE74Df8d10Bd8b81395A9b7BEfE09b2bBC868dfb|
|AccountRules|0x8f568E67317457d4847813a9cc0d2E074c74e759|

Para efetivamente verificar, entre no endereço do Blockscout disponibilizado pelo script e clique no seguinte botão:
![image](https://github.com/RBBNet/rbb/assets/111009073/8261d83c-42b7-474f-9106-094817f7f78f)

Ao clicar no botão, aparecerá a tela de verificação de smart contracts. Alguns argumentos serão pedidos, como o endereço (incluindo 0x[...]), a licença e o tipo de verificação. A licença no caso da RBB será None, e o tipo de verificação é à escolha do usuário. Nesse caso, será utilizado o Multi-part form files, embora outros possam ser selecionados.

![image](https://github.com/RBBNet/rbb/assets/111009073/d264e32e-e81a-4080-82a6-df2e29e3860b)

A versão do compilador é 0.5.9+commit.e560f70d. A versão da EVM é a default, mas, caso dê erro, tente a petersburg. Otimização desabilitada - sabe-se que ela muda o bytecode do código, o que impossibilita a verificação. Por fim, adicione na caixa pontilhada os arquivos dos smart contracts.

⚠️ Se um contrato importar outro, disponibilize também o importado. Exemplo: contrato A importa contrato B e C, então na hora de verificar o contrato A, é necessário pôr B e C junto.

Por fim, clique em verify & publish.

![image](https://github.com/RBBNet/rbb/assets/111009073/c5645498-c58a-4c89-ab39-7deb76f1230c)

## Observando os logs do nó observer manualmente
Caso tenha interesse em observar o fluxo de sincronização de blocos do observer via linha de comando, digite:

```bash
./rbb-observer --logs
```

## Desinstalação do nó observer
Para remover completamente o nó observer, digite:
```bash
./rbb-observer -r
```

## Erros

### Nó observer não subiu
É difícil, mas não impossível, que o docker-compose.yml fique com linhas duplicadas para o mapeamento de portas:
```
ports:
      - 8545:8545
      - 8545:8545
```
Nesse caso, remova uma delas no docker-compose.yml.

Quaisquer outros erros aparecerão nos logs da instalação.

### Blockscout não subiu
Verifique os logs de erro a partir do ```docker-compose logs -f```. Caso não saiba como proceder, procure informações e ajuda na [comunidade do Blockscout](https://discord.gg/blockscout).

### O carregamento de blocos no Chainlens não sai de 0%
Talvez o observer não tenha conseguido se conectar com o nó de sincronização. Reinicie o nó e veja se volta a sincronizar:
```
./rbb-observer --restart
```

## Ler também
👉 [Documentação do Blockscout](https://docs.blockscout.com/for-users/overviews)

👉 [Documentação do Chainlens](https://docs.chainlens.com/)

