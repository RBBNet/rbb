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

> [!NOTE]
> Para implantações no Windows, deve ser instalado o WSL2 e respectivamente o Docker.

## 🚀 Subindo um nó observer

Para instalar o nó `Observer`, siga estas etapas:

Linux, macOS ou Windows(WSL2 com Docker):

```
curl -sL https://raw.githubusercontent.com/RBBNet/rbb/master/obsever_user.sh | bash

```

## ☕ Usando <nome_do_projeto>

Para usar <nome_do_projeto>, siga estas etapas:

```
<exemplo_de_uso>
```

Adicione comandos de execução e exemplos que você acha que os usuários acharão úteis. Fornece uma referência de opções para pontos de bônus!
































**1.** Crie um nó chamado `observer` com o comando abaixo:
```
./rbb-cli node create observer
./rbb-cli config set nodes.observer.ports+=[\"8545:8545\"]
./rbb-cli config set nodes.observer.address=\"<IP-Externo-observer>:30303\"
```

**2.** Agora iremos ajustar o arquivo genesis.json. Acesse o seu nó `observer`, baixe o arquivo genesis.json disponível na URL a seguir e cole em `start-network/.env-configs`: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json` onde `${rede}` pode ser Lab, Piloto, etc.


**3.** No arquivo `genesis.json` que acabou de copiar, modifique o trecho `discovery`, de modo que contenha os enodes de todos os `observer-boots` a que seu `observer` terá acesso (pode ser um observer-boot seu, de outras instituições ou ambos). Como sempre, cada linha deve conter a chave pública (removendo `0x`), endereço ip e porta P2P do `observer-boot` correspondente, como no exemplo a seguir:
```
"discovery": {
      "bootnodes": ["enode://d2156e7a95f32026f41dbb9d34df915ce2b2a...2932e141beb1ce8c0@100.100.100.100:30303"]
    }
```

É importante que, no parâmetro bootnodes, as chaves públicas sejam de `observer-boots`, pois o observer realizará conexão apenas com estes nós. De maneira nenhuma o observer poderá conectar-se com outro tipo nó da rede (boot, writer, validators), pois devem se comportar similarmente aos observers que são externos à rede. 

**4.** Desabilite o permissionamento de nós **on chain** executando o comando abaixo. Você deve estar dentro do diretório start-network:
```
./rbb-cli config set nodes.observer.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false
```
Note que seu observer aceitará pedidos de conexão de quaisquer outros nós, logo faz sentido manter a porta P2P (em geral, a 30303) protegida por um firewall ou algo similar. Outra opção seria usar um permissionamento local de nó e só incluir no arquivo o(s) observer-boot(s) que seu observer for conectar.

**5.** Em seguida , a partir do nó `observer` execute o comando:
```
./rbb-cli config render-templates
docker-compose up -d
```

e aguarde o container iniciar. Se tudo ocorrer como esperado este nó se conectará com um ou mais observer-boots da rede, caso as configurações do arquivo `genesis.json` estiver em conformidade.
