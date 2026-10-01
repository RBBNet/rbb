#!/usr/bin/env node
// rbb-kms address <alias|keyId>        -> endereço Ethereum da chave no KMS
// rbb-kms sign-test <alias|keyId>      -> assina uma mensagem e verifica a recuperação do endereço
// Variáveis: AWS_REGION (padrão sa-east-1), RBB_KMS_ROLE_ARN (papel de assinatura, opcional),
//            credenciais AWS padrão (AWS_ACCESS_KEY_ID/SECRET ou AWS_PROFILE).
import { KmsSigner } from "./kms-signer.mjs";
import { verifyMessage } from "ethers";

const [cmd, keyId] = process.argv.slice(2);
if (!cmd || !keyId) { console.error("uso: rbb-kms <address|sign-test> <alias/...|keyId>"); process.exit(1); }
const signer = new KmsSigner(keyId);
const address = await signer.getAddress();
if (cmd === "address") { console.log(address); process.exit(0); }
if (cmd === "sign-test") {
  const msg = `rbb-kms-signer teste ${new Date().toISOString()}`;
  const sig = await signer.signMessage(msg);
  const ok = verifyMessage(msg, sig).toLowerCase() === address.toLowerCase();
  console.log(JSON.stringify({ address, message: msg, signature: sig, recovered_ok: ok }, null, 2));
  process.exit(ok ? 0 : 2);
}
console.error("comando inválido"); process.exit(1);
