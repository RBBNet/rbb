


# Monitoração e Responsabilidades 
Toda instituição participante deve monitorar e tratar incidentes de seus próprios nós

Toda instituição participante deve poder monitorar localmente os dados de todos os nós da RBB necessário para detecção de seus próprios incidentes.

# Tipos de Monitoração

LL- Local para detecção de incidentes

GL- Global para detecção de incidentes locais

MN- Global longo Prazo – Monitoramento de negócio 

GG- global para detecção de incidentes na rede inteira _ Saúde da rede

#  Premissas II 

GL- Global para detecção de incidentes locais
Para obter dados gerados por nós de outras instituições da rede, uma instituição pode

    (a) buscar um subconjunto dos dados diretamente de todos os nós da rede e/ou 
    
    (b) buscar dados do monitoramento GG. 
    
Buscar diretamente nos diversos nós da rede preserva a descentralização e minimiza possíveis erros uma vez que o dado é recuperado no local em que se originou.



GG- global para detecção de incidentes na rede inteira _ Saúde da rede
Pelo menos duas instituições da rede devem fazer o monitoramento com input de todos os nós da rede e oferecer uma visão global de toda a rede.

Existe uma equipe técnica responsável por cuidar da saúde global da rede, incluindo incidentes com causa desconhecida. Essa equipe pode ser composta por um subconjunto das instituições participantes, com rotatividade.

#  De onde extrair as métricas 

1. Besu e Server

Foco em estado dos nós e servidores

Contém visão em alto nível da rede


2. Diretamente na rede Blockchain 

Foco em endereços, smart contracts e transações. 
Inclui visão em alto nível dos nós
(fora do escopo no momento)

# Tipos de Métricas

1.Servidores e Processos 

Monitora o uso de CPU e uso de espaço em Disco. Também engloba uso da JVM pelo processo do Besu.
Cada instituição já deve ter padrões estabelecidos para essas métricas.


2.Especifica da RBB

Monitora sincronização, conectividade e uso da rede.
Importante alinhamento nas métricas e limites para incidentes.


![Captura de tela de 2021-12-14 15-58-25](https://user-images.githubusercontent.com/71888455/146213676-cbdc0ab7-5bfd-400e-acf1-ad3b95709f8d.png)

![Captura de tela de 2021-12-14 15-58-54](https://user-images.githubusercontent.com/71888455/146213746-08a5d304-653d-46fe-bbc7-868eeb1ea374.png)

![Captura de tela de 2021-12-14 15-59-08](https://user-images.githubusercontent.com/71888455/146213948-671d882c-1f70-43eb-a0bb-3be42dae5090.png)

![Captura de tela de 2021-12-14 15-59-24](https://user-images.githubusercontent.com/71888455/146214013-b56ecf68-1a9c-47c6-af37-225016ffcbf8.png)

![Captura de tela de 2021-12-15 12-17-46](https://user-images.githubusercontent.com/71888455/146214095-6aae336d-d28c-4b09-a38e-51fa2d24903a.png)

![Captura de tela de 2021-12-14 16-06-07](https://user-images.githubusercontent.com/71888455/146214229-4cfc1b12-c9a8-4da1-ad8e-f49013d465b2.png)

![Captura de tela de 2021-12-14 16-06-23](https://user-images.githubusercontent.com/71888455/146214233-7a48ce44-29da-4fc8-a8bd-768d8c6d7421.png)


# SLA

Nós validadores devem estar operacionais pelo menos ?% do tempo.


Nós boot e registradores devem estar operacionais pelo menos ?% do tempo. Obs.: Nós registradores também precisam respeitar SLA da aplicação que está oferecendo.

# Implementação

A troca de mensagens de monitoramento não deve impactar negativamente no desempenho dos nós da RBB

A comunicação das métricas coletadas entre as diferentes instituições seguirá o formato de dados do Prometheus. O Prometheus pode ser utilizado para a coleta, armazenamento e consulta de métricas, mas as instituições também podem optar por outra ferramenta de monitoração.

Não existe nenhuma restrição para seleção de ferramenta de gestão de incidentes. A instituição pode selecionar a mais adequada segundo a operação de sua produção de TI.

Além de servir para geração de incidentes, as métricas listadas também podem ser apresentadas em dashboards. Caso as instituições participantes optem pela adoção do Grafana, existe um modelo disponível gerado pelo BNDES. 


![Captura de tela de 2021-12-13 13-56-52](https://user-images.githubusercontent.com/71888455/146039396-ff30f6e3-aa6a-454f-81c4-0860e2dcb49b.png)








