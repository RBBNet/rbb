# Instanciar `Boot de observer` e `observer`

Este roteiro guia na criação de nós `Boot de observer` e `observer` para o laboratório da RBB usando docker. Algumas premissas simplificadoras são assumidas: 
- Boot de observer e observer devem estar em hosts diferentes;
- Boot de observer conecta-se em um nó núcleo da rede (preferencialmente um boot);
- Boot de observer realiza a comunicação entre os nós da rede e observer;
- Observer é um nó de consulta, externo a rede;
- Observer não pode enviar transações para rede, desta forma o boot deve bloquear tentativas de envio de transações.

## 1. Instanciar os nós

> [!IMPORTANT]
> Pré-requisitos
> 	- Rede com nós de núcleo funcionando (boot, validadores, writers)

### Boot de Observer

**1.** Siga o tutorial *`Roteiro para criação de uma rede`* na seção de [criação de validator e boot](https://github.com/RBBNet/rbb/blob/documentacao_observer/Roteiro_para_a_criacao_de_uma_rede.md#13---preparar-arquivos), mas substitua o nome dos nós para `boot de observer` e `observer` (utilize o roteiro em hosts diferentes para ambos os nós)`.

**2.** Acesse o `Boot de observer`, copie o genesis.json fornecido pelo boot da rede e cole em `start-network/.env-configs`. O genesis.json poderá já ter sido disponibilizado neste endereço: `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/genesis.json` onde `${rede}` pode ser Lab, Piloto, etc.

**3.** Desabilite o permissionamento executando o comando abaixo. Você deve estar dentro do diretório start-network:
```
./rbb-cli config set nodes.validator.environment.BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED=false
./rbb-cli config set nodes.validator.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false
```



**4.** Novamente, o comando para confirmar se a porta P2P está aberta para conexões tcp e udp:

```
./rbb-cli config dump
```

Deve aparecer estas portas:

	ports:
      - 30303:30303/tcp
      - 30303:30303/udp 


**5.** Em seguida , a partir do nó `Boot de observer` execute o comando docker-compose up e aguarde o container iniciar. Se tudo ocorrer como esperado este nó se conectará com um ou mais boots da rede, caso as configurações do arquivo `genesis.json` estiver em conformidade.

**6.** Acesse o host do `observer` e realize os passos 2, 3 e 4 deste documento, porém no passo 2 deve receber o `genesis.json` do boot de observer. Este genesis.json deve conter os parâmetros discovery.bootnodes a chave pública (removendo `0x`), endereço ip e porta P2P fornecidos pelo boot de observer, como no exemplo a seguir:

`"discovery": {
      "bootnodes": ["enode://d2156e7a95f32026f41dbb9d34df915ce2b2a235d93281eeda27d52cd88844d369812c78cbd1f797ad2177aba8a66607f97fa5df0ef3aa82932e141beb1ce8c0@100.100.100.100:30303"]
    }
`

É importante que no parâmetro bootnodes a chave pública seja do boot de observer, pois o observer realizará conexão apenas com este nó, de maneira nenhuma o observer poderá conectar-se com outro tipo nó da rede (boot, writer, validators), pois observers são externos à rede. 

**7.** Execute o comando `docker-compose up`. Se tudo ocorrer como esperado, o nó observer deve conectar-se ao boot de observer.
   
