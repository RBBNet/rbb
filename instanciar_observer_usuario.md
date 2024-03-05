# Instanciar nó `Observer`

Esse é um tutorial para a configuração de um observer por quaisquer pessoa externa à rede (usuário).

> Observers são nós de consulta, externos à rede.

> A função de um nó observer é ter acesso a todas as transações da rede blockchain RBB, bem como visualizar blocos e endereços ao longo do tempo. Portanto, não haverá como operar transações.

## 💻 Pré-requisitos

Antes de começar, verifique se você atendeu aos seguintes requisitos:

- Docker (Caso não tenha instalado, execute no shell do Linux o comando abaixo para instalar)
```bash
curl -fsSL https://get.docker.com | sudo sh
```

- Docker-compose
```bash
sudo apt update \
apt install -y docker-compose
```

> [!NOTE]
> - Para implantações no Windows, deve ser instalado o WSL2 e respectivamente o Docker.
> - A data e hora do sistema deve estar devidamente atualizada para que seja possível a sincronização de blocos.

## 🚀 Subindo um nó observer

Para instalar o nó `Observer`, execute o seguinte comando:

Linux, macOS ou Windows(WSL2 com Docker):

```
source <(curl -sL https://raw.githubusercontent.com/RBBNet/rbb/master/obsever_user.sh)

```
