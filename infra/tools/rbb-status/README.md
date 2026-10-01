# rbb-status

CLI em Go que mostra, do ponto de vista de um partícipe da Rede Blockchain Brasil, o estado da integração dos seus nós com a rede: quem já liberou firewall (passo 9 do roteiro de adição de nós), quem já aceita a federação do Prometheus, com quem os nós estão conectados e se os nós foram permissionados on chain.

```bash
cd infra/tools/rbb-status && go build -o rbb-status .     # Go 1.24+

rbb-status firewall --nodes lab/nodes.json --org ACIEG --role validator --ssh ubuntu@<ip do validator>
rbb-status peers --nodes lab/nodes.json --ssh ubuntu@<ip do boot>
rbb-status federation --ssh ubuntu@<ip interno do prometheus> --jump ubuntu@<ip do boot>
rbb-status permissioning --nodes lab/nodes.json --org ACIEG --node-rules 0x<NodeRulesV2Impl> --ssh ubuntu@<ip do boot>
rbb-status report --config rbb-status.json   # tudo, por SSH em cada nó; --json para automação
```

Os testes de rede rodam no nó (`--ssh`, com `--jump` para nós privados) porque as outras organizações liberam os IPs dos nós, não o da sua estação. A CLI não precisa estar instalada nos nós: envia pequenos scripts `bash` via SSH.

Formato de `rbb-status.json` (gerado por `scripts/rbb-status-config.sh` a partir dos outputs do OpenTofu):

```json
{
  "org": "ACIEG",
  "nodes_json": "network/nodes.json",
  "node_rules_v2": "0x805c...",
  "hosts": {
    "validator01":  { "role": "validator",  "ssh": "ubuntu@201.0.0.2" },
    "boot01":       { "role": "boot",       "ssh": "ubuntu@201.0.0.1" },
    "prometheus01": { "role": "prometheus", "ssh": "ubuntu@10.120.1.61", "jump": "ubuntu@201.0.0.1" }
  },
  "our_nodes": [ { "name": "validator01", "nodeType": "validator", "pubKey": "0x..." } ]
}
```
