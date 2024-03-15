# Instanciar nó `Boot de observer`

Este roteiro guia na criação de nós `observer-boots` para o laboratório da RBB usando Docker. Algumas premissas: 
- Observer-boot conecta-se com um ou mais nós boots, dependendo do caso (mais detalhes à frente);
- Observer-boot realiza a comunicação entre os nós da rede e observers;
- Observers são nós de consulta, externos à rede, sobre os quais não temos nenhum controle;
- Observers não podem enviar transações para rede. Desta forma, o observer-boot deve bloquear tentativas de envio de transações.

## Instanciar os nós

> [!IMPORTANT]
> Pré-requisitos
> 	- Rede com nós de núcleo funcionando (boot, validadores, writers)
> 	- A porta 30303 do host do observer-boot deve estar **aberta para conexões externas a partir da Internet**. 

### Boot de Observer

**1.** Crie um nó chamado `observer_boot` com o comando abaixo:
```
./rbb-cli node create observer_boot
./rbb-cli config set nodes.observer_boot.ports+=[\"8545:8545\"]
./rbb-cli config set nodes.observer_boot.address=\"<IP-externo-observer-boot>:30303\"
```

**2.** Vamos ajustar o arquivo genesis.json. Acesse o `observer-boot`, baixe o arquivo genesis.json disponível na URL a seguir e cole em `start-network/.env-configs`: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json` onde `${rede}` pode ser Lab, Piloto, etc.


Aqui temos duas situações para o observer-boot:

 	1. A empresa não possui nó boot
  
	2. A empresa possui nó boot
 
- Para o caso `1. A empresa não possui nó boot`, o observer-boot se conectará aos boot de outras instituições via discovery. Neste caso, garanta que a seção `discovery` do `genesis.json` contenha todos os boot nodes das outras instituições (ele pode estar vazio ou com uma lista - verifique).
  
- Para o caso `2. A empresa possui nó boot`, o observer-boot se conectará ao boot da sua própria instituição, usando static-nodes. Neste caso será preciso excluir o trecho `discovery` mostrado na imagem abaixo do arquivo genesis.json:

![](https://i.imgur.com/mdU0lYT.png))

 Crie o arquivo `volumes/observer_boot/static-nodes.json` e inclua o enode do boot da própria instituição (usando **IP interno**).

  Modelo:

  ```json
  [ 
  "enode://<chave-pública-SEM-0x>@<ip-interno>:<porta-P2P>"
  ]
  ```

**3.** Desabilite o permissionamento **on chain** de contas e nós, executando o comando abaixo. Você deve estar dentro do diretório start-network:
```
./rbb-cli config set nodes.observer_boot.environment.BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED=false
./rbb-cli config set nodes.observer_boot.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false

```

**4.** Habilite o permissionamento **de contas** no modo "local", ou seja, usando um arquivo. 
```
./rbb-cli config set nodes.observer_boot.environment.BESU_PERMISSIONS_ACCOUNTS_CONFIG_FILE_ENABLED=true
./rbb-cli config set nodes.observer_boot.environment.BESU_PERMISSIONS_ACCOUNTS_CONFIG_FILE=\"/var/lib/besu/permissioned-accounts.toml\"

```
Crie o arquivo `volumes/observer_boot/permissioned-accounts.toml` com o seguinte conteúdo (a lista é vazia mesmo):
```
accounts-allowlist=[]
```

**6.** Em seguida , a partir do nó `observer-boot` execute o comando:
```
./rbb-cli config render-templates
docker-compose up -d
```

e aguarde o container iniciar. 

> [!IMPORTANT]
> Lembre-se de permissionar o observer-boot recém criado na blockchain. Caso contrário o nó não irá sincronizar os blocos.
