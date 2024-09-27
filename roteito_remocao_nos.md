# Roteiro para remoção de nós de uma rede RBB

Este roteiro tem como objetivo a remoção de nós de uma rede RBB já estabelecida e funcional.

**Observação**: **ESTE ROTEIRO AINDA ESTÁ EM ELABORAÇÃO** e ainda pode sofrer alterações.


## 1 - Comunicação

Comunique aos demais partícipes da rede sobre a remoção de nós na rede. Algumas atividades deverão ser realizadas em conjunto para a correta reconfiguração da rede, logo há necessidade de uma coordenação entre os partícipes.


## 2 - Atualização da documentação do(s) nó(s) removido(s)

A documentação da RBB deve ser atualizada. O(s) nó(s) a ser(em) removido(s) deve(m) ser sinalizado(s) com `status` de `retired`, para que fique explícito que deixará(ão) de fazer parte da rede.

Para isso, deve-se atualizar o arquivo `nodes.json`, que se encontra em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/nodes.json`, onde `${rede}` pode assumir o valor `lab` (laboratório) ou `piloto`, a depender de qual rede o(s) nó(s) será(ão) removido(s). 


## 3 - Remoção de nó validator

Caso seja necessário remover um nó validator, **antes de seu desligamento**, é necessário retirá-lo do algoritmo de consenso. Para isso, os partícipes associados precisam realizar uma votação para tal fim. Atingindo-se a metade mais um dos votos, o validator é retirado do consenso.

**Observações**:
- O desligamento de um validator antes que seja retirado do algoritmo de consenso é **prejudicial ao bom desempenho da rede**, pois **aumenta o tempo médio de produção de blocos**. Portanto, **a votação para remoção do validator é pré-requisito essencial para seu desligamento**.
- Uma vez iniciada uma votação, ela deve ser terminada em um determinado limite de tempo. Portanto, esta precisa ser uma atividade coordenada.

A votação deve ser realizada no nó validator de cada partícipe associado através do comando:

```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["<id-validator-SEM-0x>",false], "id":1}' <ip-interno-validator>:<porta-json-rpc>
```

Os identificadores dos validators pode ser obtido em `https://github.com/RBBNet/participantes/tree/main/`**${rede}**`/nodes.json` no atributo `id` de cada nó.


# 4 - Permissionamento do(s) nó(s) removido(s)

De forma a manter a configuração da rede atualizada e a zelar pela segurança, o(s) nó(s) removido(s) deve(m) ter seu permissionamento revogado. Esta revogação deve ser feita através de execução dos *smart contracts* da RBB específicos para essa função, que devem ser executados por uma conta de administração.

Solicite que um administrador da rede realize a(s) devida(s) revogação(ões).


## 5 - Regras de firewall

De forma a manter a configuração da rede atualizada e a zelar pela segurança, os partícipes devem atualizar suas regras de firewall, impedindo os acessos ao(s) nó(s) removido(s).

## 5.1 - Configurações na instituição que estiver removendo nó(s)

As seguintes regras de firewall deverão ser **excluídas** por sua instituição:

- **Excluir** regras para seus validators removidos:
  - Conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu validator.
  - Conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos outros validators que integram a RBB.
- **Excluir** regras para seus boots removidos:
  - Conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu boot.
  - Conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos outros boots que integram a RBB, além dos writers dos **partícipes parceiros**.
- **Excluir** regras para seus observer-boots removidos: 
  - Conexão (inbound) no `<ip-externo>:<porta-p2p>` do seu observer-boot.
- **Excluir** regras para seus Prometheus removidos:
  - Conexão (inbound) no `<ip-externo>:<porta-prometheus>` do seu Prometheus.
  - Conexão (outbound) para os `<ip-externo>:<porta-prometheus>` dos outros Prometheus que integram a RBB.

## 5.2 Configurações pelos demais partícipes

As seguintes regras de firewall deverão ser excluídas pelas demais instituições:

- **Excluir** regras para seus validators:
  - Conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus validators a partir dos validators removidos da RBB.
  - Conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos validators removidos da RBB.
- **Excluir** regras para seus boots:
  - Conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus boots a partir dos boots removidos da RBB.
  - Conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos boots removidos da RBB.
- Os **partícipes parceiros** devem **excluir** regras para seus writers:
  - Conexão (inbound) nos `<ip-externo>:<porta-p2p>` dos seus writers a partir dos boots removidos da RBB.
  - Conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos boots removidos da RBB.
- Os **partícipes parceiros** devem **excluir** regras para seus observer-boots:
  - Conexão (outbound) para os `<ip-externo>:<porta-p2p>` dos boots removidos da RBB.
- **Excluir** regras para seus Prometheus:
  - Conexão (inbound) no `<ip-externo>:<porta-prometheus>` dos seus Prometheus a partir dos Prometheus removidos da RBB.
  - Conexão (outbound) para os `<ip-externo>:<porta-prometheus>` dos Prometheus removidos da RBB.


# 6 - Ajustar genesis e static-nodes dos nós dos outros partícipes associados 

As atividades a seguir deverão ser executadas pelos **partícipes associados** para cada nó removido, de acordo com seu tipo.

## 6.1 Remoção de boot

- **Remova** na seção apropriada do arquivo `.env.configs/genesis.json` do boot da instituição o enode do boot removido da rede:

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-boot-removido-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```

## 6.2 Remoção de validator

- **Remova** do arquivo `volumes/validator<sequencial>/static-nodes.json` do validator da instituição o enode do validator removido da rede:

```json
[ 
  ...
  "enode://<chave-publica-validator-removido-SEM-0x>@<ip-externo>:<porta-p2p>"
]
```


# 7 - Ajustar genesis dos nós dos partícipes parceiros  

As atividades a seguir deverão ser executadas pelos **partícipes parceiros** para cada nó removido, de acordo com seu tipo.

## 7.1 - Remoção de boot

- **Remova** na seção apropriada do arquivo `.env.configs/genesis.json` do writer e do observer-boot (se houver) da instituição o enode do boot removido da rede:

```json
  "discovery": {
    "bootnodes" : 
    [
      ...    
      "enode://<chave-publica-boot-removido-SEM-0x>@<ip-externo>:<porta-p2p>"
    ]
  },
```


# 8 - Ajuste na monitoração pelos demais partícipes

Os demais partícipes devem ajustar a configuração de seus Prometheus, para que deixem de capturar as métricas do(s) nó(s) removido(s) da rede. Para tanto, faz-se necessário a **remoção** do alvo (*target*) cadastrado para o Prometheus que foi removido da rede, no job `rbb-federado`, cadastrado no arquivo `prometheus.yml`:
```
...
scrape_configs:
  ...
  # Job para coletar as métricas de outras organizações.
  # Inclua aqui os alvos das outras organizações (Prometheus expostos).
  - job_name: rbb-federado
    ...
    static_configs:
      ...
      - targets: [ '<ip do prometheus removido>:<porta do prometheus removido>' ]
        labels:
          organization: '<nome da organização do prometheus removido>'
```

Após o ajuste no arquivo, deve-se realizar a recarga da configuração no Prometheus. Recomendamos que o contêiner Docker do Prometheus seja reiniciado:
```
docker-compose restart
```

**Observação**: Esse comando deve ser executado na pasta onde estiver o arquivo `docker-compose.yml` do Prometheus.

Opcionalmente, caso não se queira reiniciar o contêiner, é possível sinalizar ao Prometheus a necessidade de recarga de configuração durante sua execução, sem parada do serviço. Mais informações sobre esse procedimento podem ser obtidas na [documentação do Prometheus](https://prometheus.io/docs/prometheus/latest/configuration/configuration/).

