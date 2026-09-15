# Dados da rede piloto (mainnet)

Coloque aqui os arquivos obtidos no repositório privado `RBBNet/participantes/piloto/`
(acesso restrito aos partícipes):

| Arquivo | Origem | Uso |
|---|---|---|
| `genesis.json` | `participantes/piloto/genesis.json` | embutido no bootstrap de cada nó Besu |
| `boots.txt` | enodes dos **boots das outras organizações** (um por linha, IP externo), a partir de `nodes.json` | `rbb-link-nodes.sh`: discovery do boot próprio |
| `validators.txt` | enodes dos **validators das outras organizações** (um por linha, IP externo) | `rbb-link-nodes.sh`: static-nodes do validator |
| `clients.pem` | certificados concatenados de `participantes/piloto/certificados` | `rbb-link-nodes.sh`: mTLS do Prometheus |

Todos estão ignorados pelo git (exceto este README).
