# Dados da rede lab (testnet)

Arquivos obtidos do repositório privado `RBBNet/participantes/lab/` (acesso restrito aos partícipes).
Gere todos automaticamente com o `gh` autenticado em uma conta membro da org RBBNet:

```bash
../../../scripts/rbb-sync-participantes.sh testnet <NOME-DA-ORGANIZACAO>   # ex.: BNDES
```

| Arquivo | Origem | Uso |
|---|---|---|
| `genesis.json` | `participantes/lab/genesis.json` | embutido no bootstrap de cada nó Besu |
| `docker-compose.yml.hbs` | `participantes/lab/docker-compose.yml.hbs` (se existir) | template de compose específico da rede |
| `nodes.json` | `participantes/lab/nodes.json` | referência; fonte dos arquivos abaixo |
| `boots.txt` | boots ativos das **outras** organizações | `rbb-link-nodes.sh`: discovery do boot próprio |
| `validators.txt` | validators ativos das **outras** organizações | `rbb-link-nodes.sh`: static-nodes do validator |
| `federation.json` | Prometheus (8443) ativos das **outras** organizações | `tofu apply` e `rbb-link-nodes.sh`: federação |
| `clients.pem` | `participantes/lab/certificados/*.pem` concatenados | `rbb-link-nodes.sh`: mTLS do Prometheus |

Todos são ignorados pelo git (exceto este README): contêm dados reservados aos partícipes.
