# Dados da rede piloto (mainnet)

Arquivos obtidos do repositório privado `RBBNet/participantes/piloto/` (acesso restrito aos partícipes).
Gere todos automaticamente com o `gh` autenticado em uma conta membro da org RBBNet:

```bash
../../../scripts/rbb-sync-participantes.sh mainnet <NOME-DA-ORGANIZACAO>   # ex.: BNDES
```

| Arquivo | Origem | Uso |
|---|---|---|
| `genesis.json` | `participantes/piloto/genesis.json` | embutido no bootstrap de cada nó Besu |
| `docker-compose.yml.hbs` | `participantes/piloto/docker-compose.yml.hbs` (se existir) | template de compose específico da rede |
| `nodes.json` | `participantes/piloto/nodes.json` | referência; fonte dos arquivos abaixo |
| `boots.txt` | boots ativos das **outras** organizações | `rbb-link-nodes.sh`: discovery do boot próprio |
| `validators.txt` | validators ativos das **outras** organizações | `rbb-link-nodes.sh`: static-nodes do validator |
| `federation.json` | Prometheus (8443) ativos das **outras** organizações | `tofu apply` e `rbb-link-nodes.sh`: federação |
| `participants.json` | IPs por papel (validators, boots, prometheus) das **outras** organizações | `tofu apply`: firewall por papel (passo 9) |
| `our-nodes.json` | gerado por `rbb-node-info.sh` a partir dos nossos nós | `rbb-publish-nodes.sh`: PR no `participantes` (passo 6) |
| `clients.pem` | `participantes/piloto/certificados/*.pem` concatenados | `rbb-link-nodes.sh`: mTLS do Prometheus |

Todos são ignorados pelo git (exceto este README): contêm dados reservados aos partícipes.
