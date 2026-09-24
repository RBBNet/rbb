// Teste offline: simula o KMS com uma chave secp256k1 local (DER SPKI + assinatura DER)
import { KmsSigner, publicKeyFromSpki, rsFromDer } from "./kms-signer.mjs";
import { SigningKey, Wallet, verifyMessage, Transaction, JsonRpcProvider, getBytes } from "ethers";
import { createPrivateKey, createPublicKey, sign as nodeSign } from "node:crypto";
import assert from "node:assert/strict";

const wallet = Wallet.createRandom();
// chave privada em formato PKCS8/DER para o node:crypto assinar como o KMS (ECDSA_SHA_256 sobre o digest)
const raw = Buffer.from(wallet.privateKey.slice(2), "hex");
const pkcs8 = createPrivateKey({ key: Buffer.concat([
  Buffer.from("308184020100301006072a8648ce3d020106052b8104000a046d306b0201010420", "hex"), raw,
  Buffer.from("a144034200", "hex"), Buffer.from(SigningKey.computePublicKey(wallet.privateKey, false).slice(2), "hex"),
]), format: "der", type: "pkcs8" });
const spkiDer = createPublicKey(pkcs8).export({ format: "der", type: "spki" });

const fakeKms = { send: async (cmd) => {
  const name = cmd.constructor.name;
  if (name === "GetPublicKeyCommand") return { PublicKey: new Uint8Array(spkiDer) };
  if (name === "SignCommand") {
    assert.equal(cmd.input.MessageType, "DIGEST");
    // KMS assina o digest: emulamos com sign() sem hash extra sobre o digest? node exige algoritmo; usamos
    // 'sha256' com o digest como mensagem NÃO daria o mesmo. Em vez disso, assinamos com a SigningKey do ethers
    // e reencodamos em DER, que é o formato retornado pelo KMS.
    const sig = new SigningKey(wallet.privateKey).sign(cmd.input.Message);
    const r = Buffer.from(sig.r.slice(2), "hex"), s = Buffer.from(sig.s.slice(2), "hex");
    const int = (b) => { const x = b[0] & 0x80 ? Buffer.concat([Buffer.from([0]), b]) : b; return Buffer.concat([Buffer.from([0x02, x.length]), x]); };
    const body = Buffer.concat([int(r), int(s)]);
    return { Signature: new Uint8Array(Buffer.concat([Buffer.from([0x30, body.length]), body])) };
  }
  throw new Error("comando inesperado " + name);
} };

const signer = new KmsSigner("alias/teste", { client: fakeKms });
assert.equal((await signer.getAddress()).toLowerCase(), wallet.address.toLowerCase(), "endereço derivado do SPKI");
const msg = "rbb teste";
const sig = await signer.signMessage(msg);
assert.equal(verifyMessage(msg, sig).toLowerCase(), wallet.address.toLowerCase(), "assinatura de mensagem recuperável");
const rawTx = await signer.signTransaction({ to: wallet.address, value: 0n, nonce: 1, gasLimit: 21000n, gasPrice: 0n, chainId: 648629n });
assert.equal(Transaction.from(rawTx).from.toLowerCase(), wallet.address.toLowerCase(), "transação assinada recupera o remetente");
console.log("OK: endereço, mensagem e transação (chainId 648629) assinados via KMS simulado");
