# Instanciar `Boot de observer` e `observer`

Este roteiro guia na criação de nós `Boot de observer` e `observer` para o laboratório da RBB usando Docker. Algumas premissas simplificadoras são assumidas: 
- Boot de observer e observer devem estar em hosts diferentes;
- Boot de observer conecta-se com um nó núcleo da rede (preferencialmente um boot);
- Boot de observer realiza a comunicação entre os nós da rede e observer;
- Observer é um nó de consulta, externo a rede;
- Observer não pode enviar transações para rede, desta forma o boot deve bloquear tentativas de envio de transações.

## Instanciar os nós

> [!IMPORTANT]
> Pré-requisitos
> 	- Rede com nós de núcleo funcionando (boot, validadores, writers)

### Boot de Observer

**1.** Crie um nó chamado `observer-boot` com o comando abaixo:
```
./rbb-cli node create observer-boot
./rbb-cli config set nodes.observer-boot.ports+=[\"8545:8545\"]
./rbb-cli config set nodes.observer-boot.address=\"<IP-Externo-observer-boot>:30303\"
```

**2.** Vamos ajustar o arquivo genesis.json. Acesse o `observer-boot`, baixe o arquivo genesis.json disponível na URL a seguir e cole em `start-network/.env-configs`: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json` onde `${rede}` pode ser Lab, Piloto, etc.


Aqui temos duas situações para o observer-boot:

 	1. A empresa não possui nó boot
  
	2. A empresa possui nó boot
 
- Para o caso `1. A empresa não possui nó boot`, o observer-boot se conectará aos boot de outras instituições via discovery. Neste caso não será necessário fazer demais alterações no arquivo baixado `genesis.json`.

- Para o caso `2. A empresa possui nó boot`, o observer-boot se conectará ao boot da sua rede via static-nodes. Neste caso será preciso excluir o trecho `discovery` mostrado na imagem abaixo:

![](https://i.imgur.com/mdU0lYT.png))

Desabilite a descoberta de nós com o seguinte comando:

  ```bash
  ./rbb-cli config set nodes.observer-boot.environment.BESU_DISCOVERY_ENABLED=false
  
  ```
 Crie o arquivo `volumes/observer-boot/static-nodes.json` e inclua o enode do boot da própria instituição (usando **IP interno**).

  Modelo:

  ```json
  [ 
  "enode://<chave-pública-SEM-0x>@<ip-interno>:<porta>"
  ]
  ```

**3.** Desabilite o permissionamento de contas e nós, executando o comando abaixo. Você deve estar dentro do diretório start-network:
```
./rbb-cli config set nodes.observer-boot.environment.BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED=false
./rbb-cli config set nodes.observer-boot.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false
```

**4.** Novamente, o comando para confirmar se a porta P2P está aberta para conexões tcp e udp:

```
./rbb-cli config dump
```

Deve aparecer estas portas:

	ports:
      - 30303:30303/tcp
      - 30303:30303/udp 


**5.** Em seguida , a partir do nó `observer-boot` execute o comando:
```
./rbb-cli config render-templates
docker-compose up -d
```

e aguarde o container iniciar. Se tudo ocorrer como esperado este nó se conectará com um ou mais boots da rede, caso as configurações do arquivo `genesis.json` estiver em conformidade.



### Observer

**1.** Crie um nó chamado `observer` com o comando abaixo:
```
./rbb-cli node create observer
./rbb-cli config set nodes.observer.ports+=[\"8545:8545\"]
./rbb-cli config set nodes.observer.address=\"<IP-Externo-observer>:30303\"
```

**2.** Acesse o `observer`, copie o genesis.json do `observer-boot` e cole em `start-network/.env-configs`.

**3.** No arquivo `genesis.json` que acabou de trazer do `observer-boot`, modifique o trecho `discovery`, de modo que contenha apenas os dados do `observer-boot`, deve conter a chave pública (removendo `0x`), endereço ip e porta P2P do `observer-boot`, como no exemplo a seguir:
```
"discovery": {
      "bootnodes": ["enode://d2156e7a95f32026f41dbb9d34df915ce2b2a...2932e141beb1ce8c0@100.100.100.100:30303"]
    }
```

É importante que no parâmetro bootnodes a chave pública seja do `observer-boot`, pois o observer realizará conexão apenas com este nó, de maneira nenhuma o observer poderá conectar-se com outro tipo nó da rede (boot, writer, validators), pois observers são externos à rede. 

**4.** Desabilite o permissionamento executando o comando abaixo. Você deve estar dentro do diretório start-network:
```
./rbb-cli config set nodes.observer.environment.BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED=false
./rbb-cli config set nodes.observer.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false
```

**5.** Novamente, o comando para confirmar se a porta P2P está aberta para conexões tcp e udp:

```
./rbb-cli config dump
```

Deve aparecer estas portas:

	ports:
      - 30303:30303/tcp
      - 30303:30303/udp 





**6.** Em seguida , a partir do nó `observer` execute o comando:
```
./rbb-cli config render-templates
docker-compose up -d
```

e aguarde o container iniciar. Se tudo ocorrer como esperado este nó se conectará com um ou mais boots da rede, caso as configurações do arquivo `genesis.json` estiver em conformidade.
