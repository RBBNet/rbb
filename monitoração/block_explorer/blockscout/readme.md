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

1. Docker v20.10+
2. Docker-compose v2.24+

:pushpin: Caso você não tenha o Docker instalado, acesse a [página de instalação do Docker](https://www.docker.com/products/docker-desktop/).
   
> [!NOTE]
> - Para implantações no Windows, deve ser instalado o WSL2 (caso não esteja instalado) e, em seguida, o Docker.
> - A data e hora do sistema deve estar devidamente atualizada para que seja possível a sincronização de blocos.

## Subindo nó observer

Para instanciar um nó observer, execute o seguinte comando:
```
source <(curl -sL https://raw.githubusercontent.com/RBBNet/rbb/master/monitora%C3%A7%C3%A3o/block_explorer/blockscout/observer_user.sh)
```
Ao término da instalação, você poderá acompanhar as transações e visualização dos blocos acessando a URL informada ao final da instalação. Acesse utilizando um navegador como Chrome, Firefox, Edge ou demais navegadores.

## Utilização
Ao acessar a dashboard, você já poderá observar os blocos sendo baixados e indexados. Nesta etapa inicial, é esperado que a sincronização com a RBB leve um tempo considerável para ocorrer, até que todos os blocos possam ser recebidos.

![](https://i.imgur.com/GqdSBuj.png)

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

## Ler também

[Guia do Blockscout para o usuário](https://docs.blockscout.com/for-users/overviews)
