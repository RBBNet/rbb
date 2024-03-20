# Instanciar nó `Observer`

Esse é um tutorial para a configuração de um observer por quaisquer pessoa externa à rede (usuário).

> Observers são nós de consulta, externos à rede.

> A função de um nó observer é ter acesso a todas as transações da rede blockchain RBB, bem como visualizar blocos e endereços ao longo do tempo. Portanto, não haverá como operar transações.

### Recursos do sistema

**Mínimo**
- RAM: 4 GB
- CPU: Intel Pentium 4
- Disco: ~80 GB

## 💻 Pré-requisitos

Antes de começar, verifique se você atendeu aos seguintes requisitos:

```
1. Docker e Docker-compose
2. Git
```

### 1. Docker e Docker-compose (Caso já tenha o Docker instalado e já configurado, pule esta etapa)
- Docker + configuração básica para usuário comum
```bash
curl -fsSL https://get.docker.com | sudo sh && dockerd-rootless-setuptool.sh && su - ${USER}
```

- Docker-compose
```bash
sudo apt update \
apt install -y docker-compose
```

> [!NOTE]
> - Para implantações no Windows, deve ser instalado o WSL2 (caso não esteja instalado) e, em seguida, o Docker.
> - A data e hora do sistema deve estar devidamente atualizada para que seja possível a sincronização de blocos.

## 🚀 Subindo nó observer

Para instalar o nó `Observer`, execute o seguinte comando:

Linux, macOS ou Windows (WSL2 com Docker):

```
source <(curl -sL https://raw.githubusercontent.com/RBBNet/rbb/master/monitora%C3%A7%C3%A3o/block_explorer/chainlens-free/observer_user.sh)

```

Ao término da instalação, você poderá acompanhar as transações e visualização dos blocos acessando `http://localhost:5001` usando Chrome, Firefox, Edge ou demais navegadores.

## Utilização

Ao acessar a dashboard, clique no botão **Status** caso queira acompanhar o status da sincronização (download) dos blocos da RBB (Rede blockchain do Brasil) conforme mostra a imagem abaixo:

![](https://i.imgur.com/jdFnmmu.png)

Enquanto a sincronização acontece, você já poderá navegar e visualizar as informações já obtidas da blockchain.
