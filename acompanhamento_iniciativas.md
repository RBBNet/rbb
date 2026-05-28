# Acompanhamento de Atividades no Kanban

Este documento apresenta um conjunto de diretrizes e boas práticas sugeridas pela Coordenação de Evolução  para auxiliar na organização, abertura de *issues* e governança das atividades acompanhadas no quadro Kanban.

## Classificação por *Labels*

O uso de *labels* é uma prática recomendada para identificar e categorizar os tipos de atividades do projeto [RBB Maturação do Piloto](https://github.com/orgs/RBBNet/projects/4). Ao registrar uma nova tarefa, vale a pena avaliar se ela se enquadra nas descrições abaixo para aplicar as respectivas etiquetas:

* **`iniciativa`**: Recomendada para identificar Iniciativas ou "macro atividades". Essas tarefas costumam ter um acompanhamento mais próximo e seu andamento será reportado nas reuniões do Comitê Executivo.

* **`infraestrutura`**: Indicada para sinalizar atividades mais técnicas que envolvam operações de infraestrutura — como, por exemplo, definições de regras de firewall ou alterações no arquivo `genesis.json`.

> Verifique a adequação dessas etiquetas sempre que uma nova atividade for registrada. Além disso, novas labels podem ser criadas sob demanda caso aja a necessidade.

### Visões de Acompanhamento (*Views*)

Para facilitar o acompanhamento do fluxo, o painel **RBB Maturação do Piloto** já conta com visões dedicadas e filtradas para essas atividades:

* **Filtro de Iniciativas:** [Acessar *View* de Iniciativas](https://github.com/orgs/RBBNet/projects/4/views/20) 

* **Filtro de Infraestrutura:** [Acessar *View* de Infraestrutura](https://github.com/orgs/RBBNet/projects/4/views/21) 


## Alinhamento de Campos do Projeto

Com o objetivo de manter uma boa previsibilidade de prazos e responsabilidades, sugere-se o preenchimento dos seguintes campos no painel do projeto **RBB Maturação do Piloto**:

| Campo do Projeto | Descrição |
| --- | --- |
| **Status** | Indica a situação atual da demanda (ex: "Em andamento").|
| **Data de início** | Destinada a marcar a real data de início da atividade.|
| **Data de fim** | Destinada a marcar a real data de término da atividade.|
| **Solicitante** | Indica a instituição que gerou a demanda ou que está solicitando a ação de outra instituição.|
| **Executor** | Indica a instituição responsável pelo desenvolvimento e execução da tarefa.|
| **Data alvo** | Registra a data que está planejada para o fim da atividade.|
| **Data alvo inicial** | Registra a primeira data alvo que foi planejada para o fim da atividade.|

> Mantemos o campo **Data alvo inicial** fixo após sua primeira definição. Caso a atividade precise ser replanejada e a data planejada mude, alteramos apenas no campo **Data alvo**. Isso ajuda a manter um histórico sobre o planejamento original e eventuais desvios.


## Uso de *Sub-issues* e Dependências

A adoção de *sub-issues* é incentivada por trazer benefícios práticos:

* Facilita o rastreio de "macro atividades" e iniciativas que possuam desdobramentos ou tarefas derivadas.

* Permite visualizar de forma assíncrona o andamento da *issue* principal à medida que as *sub-issues* vão sendo concluídas.

* Ajuda a identificar de forma mais rápida e visual os possíveis bloqueios e dependências do fluxo.

> Sempre que uma nova atividade for desdobramento de outra (especialmente se for derivada de uma iniciativa) e não possuir um peso ou complexidade tão grande que justifique uma iniciativa isolada, é uma boa prática criá-la como uma *sub-issue* da atividade principal correspondente.


## Acionamento de Times (*Teams*)

Para simplificar a comunicação assíncrona e garantir que as notificações cheguem corretamente aos membros das instituições da RBB, orienta-se o uso da estrutura de Times do GitHub:

* Cada instituição deve criar e fazer a gestão do seu próprio time.

* Os times podem ser estruturados diretamente na área designada da organização: [Acessar Times RBBNet](https://github.com/orgs/RBBNet/teams).

Quando houver a necessidade de marcar ou chamar a atenção de uma instituição em comentários ou descrições de issues, basta utilizar a seguinte sintaxe: `@RBBNet/<nome-do-time-em-minúsculo>`