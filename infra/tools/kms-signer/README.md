# rbb-kms-signer

Assina transações Ethereum da RBB com uma chave **secp256k1 no AWS KMS**: a chave privada nunca existe fora do KMS, cada assinatura fica no CloudTrail e a permissão de assinar é revogável.

```bash
cd infra/tools/kms-signer && npm install
export AWS_REGION=sa-east-1            # credenciais AWS pelo ambiente ou AWS_PROFILE
export RBB_KMS_ROLE_ARN=arn:aws:iam::<conta>:role/<org>-rbb-lab-admin-signer   # opcional: assume o papel de assinatura
node cli.mjs address alias/exemplo-rbb-lab-admin      # endereço a informar à governança da RBB
node cli.mjs sign-test alias/exemplo-rbb-lab-admin    # assina e verifica (gera um evento kms:Sign no CloudTrail)
```

`KmsSigner` (em `kms-signer.mjs`) é um `Signer` do ethers v6 e pode ser usado no lugar de `new Wallet(PRIVATE_KEY)` em scripts de permissionamento:

```js
import { JsonRpcProvider } from "ethers";
import { KmsSigner } from "./kms-signer.mjs";
const signer = new KmsSigner("alias/exemplo-rbb-lab-admin").connect(new JsonRpcProvider(process.env.JSON_RPC_URL));
```
