# Instanciar nó "observer" com explorador de blocos *Blockscout*
---

Esse é um tutorial para a configuração de um nó observer para o usuário (qualquer pessoa externa à rede). 

* Nós observer são nós de consulta. A função deles é ter acesso a todas as transações da rede blockchain RBB, bem como visualizar blocos e endereços ao longo do tempo. Portanto, não haverá como operar transações.

## Recursos do sistema

Redes blockchain podem variar em tamanhos e requisitos, porém, para ter boa performance, é recomendado:

- **CPU**: 16 core, 32 thread
- **RAM**: 128 GB
- **Disco**: 500 GB

Tendo em vista que essa não é uma realidade alcançável para o público em geral, os requisitos mínimos são:

- **CPU**: 6 core, 12 thread
- **RAM**: 16 GB
- **Disco**: 80 GB 

:warning: Pode ser que o *Blockscout* consiga funcionar em máquinas mais modestas. Caso a máquina em questão não consiga se aproximar dos requisitos mínimos, é interessante utilizar o *Chainlens*, uma alternativa mais leve.

## Pré-requisitos

Antes de começar, verifique se você atendeu aos seguintes requisitos:
1. Git
2. Docker v20.10+
      - [página de instalação do Docker](https://www.docker.com/products/docker-desktop/)
3. Docker compose v2.24+
      > [!NOTE] Notamos que as as versões do compose 2.24.7, 2.25.0 e 2.26.0 não se mostraram compatíveis com o Blockscout. )
      - [página de instalação do compose](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually)

> [!NOTE]
> 
> - Para implantações no Windows, deve ser instalado o WSL2 (caso não esteja instalado) e, em seguida, o Docker.
> - A data e hora do sistema deve estar devidamente atualizada para que seja possível a sincronização de blocos.

## Subindo nó observer

Para instanciar um nó observer, execute o seguinte comando:
```
source <(curl -sL https://raw.githubusercontent.com/RBBNet/rbb/master/monitora%C3%A7%C3%A3o/block_explorer/observer_user.sh -b)
```
Ao término da instalação, você poderá acompanhar as transações e visualização dos blocos acessando a URL informada ao final da instalação. Acesse utilizando um navegador como Chrome, Firefox, Edge ou demais navegadores.

## Utilização
Ao acessar a dashboard, você já poderá observar os blocos sendo baixados e indexados. Nesta etapa inicial, é esperado que a sincronização com a RBB leve um tempo considerável para ocorrer, até que todos os blocos possam ser recebidos.

![](https://i.imgur.com/GqdSBuj.png)

## Verificação de contratos

Após subir o Blockscout, é necessário esperar até que todos os blocos estejam indexados. Quando isso ocorrer, você poderá usar os serviços do Blockscout, destacando-se o de **verificação de contratos**, apontado na imagem a seguir:

![image](https://github.com/RBBNet/rbb/assets/111009073/b1c58818-10d2-447c-a9ee-52c50574e35d)

Ao clicar no botão, aparecerá a tela de verificação de smart contracts. Alguns argumentos serão pedidos, como o endereço (incluindo 0x[...]), a licença e o tipo de verificação. A licença no caso da RBB será *None*, e o tipo de verificação é à escolha do usuário. Nesse caso, será utilizado o *Multi-part form files*, embora outros possam ser selecionados.

![image](https://github.com/RBBNet/rbb/assets/111009073/075e4c4b-9d1c-40ea-8c90-a0dfaff9dd7c)

A versão do compilador é 0.5.9+commit.c68bc34e. A versão da EVM é a default, mas, caso dê erro, tente a *petersburg*. Otimização desabilitada - sabe-se que ela muda o bytecode do código, o que impossibilita a verificação. Por fim, adicione na caixa pontilhada os arquivos dos smart contracts.

:warning: Se um contrato importar outro, disponibilize também o importado. Exemplo: contrato A importa contrato B e C, então na hora de verificar o contrato A, é necessário pôr B e C junto.

Por fim, clique em *verify & publish*.

![image](https://github.com/RBBNet/rbb/assets/111009073/03d0e02a-a5cf-441d-9ec3-041ed81c7810)


## Erros
:pushpin: *Meu observer não subiu*

É possível que o docker-compose.yml fique com linhas duplicadas para o mapeamento de portas:
```
ports:
      - 8545:8545
      - 8545:8545
```

Nesse caso, remova uma delas no docker-compose.yml.

:pushpin: *Não consigo subir o Blockscout*

Verifique os logs com *docker-compose logs -f* no seu terminal e proceda de acordo com os erros que aparecem. 

:pushpin: *Socorro! Quero subir o Blockscout, mas aparece um monte de erro!*

Procure o [Discord do Blockscout](https://discord.com/invite/blockscout). 

## Ler também

[Guia do Blockscout para o usuário](https://docs.blockscout.com/for-users/overviews)
