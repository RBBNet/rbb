# Dados da rede lab (testnet)

Coloque aqui os arquivos obtidos no repositório privado `RBBNet/participantes/lab/`
(acesso restrito aos partícipes):

| Arquivo | Origem | Uso |
|---|---|---|
| `genesis.json` | `participantes/lab/genesis.json` | embutido no bootstrap de cada nó Besu |
| `boots.txt` | enodes dos **boots das outras organizações** (um por linha, IP externo), a partir de `nodes.json` | `rbb-link-nodes.sh`: discovery do boot próprio |
| `validators.txt` | enodes dos **validators das outras organizações** (um por linha, IP externo) | `rbb-link-nodes.sh`: static-nodes do validator |
| `clients.pem` | certificados concatenados de `participantes/lab/certificados` | `rbb-link-nodes.sh`: mTLS do Prometheus |

Todos estão ignorados pelo git (exceto este README).
