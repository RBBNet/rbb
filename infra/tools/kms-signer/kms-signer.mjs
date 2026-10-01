// Signer do ethers v6 que assina com uma chave secp256k1 no AWS KMS.
// A chave privada nunca sai do KMS: usamos GetPublicKey (endereço) e Sign (ECDSA_SHA_256).
import { KMSClient, GetPublicKeyCommand, SignCommand } from "@aws-sdk/client-kms";
import { fromTemporaryCredentials } from "@aws-sdk/credential-providers";
import * as asn1js from "asn1js";
import { AbstractSigner, Signature, Transaction, computeAddress, getBytes, hashMessage, keccak256, recoverAddress, resolveAddress, TypedDataEncoder } from "ethers";

const SECP256K1_N = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141");

function kmsClient({ region, roleArn }) {
  const cfg = { region };
  if (roleArn) cfg.credentials = fromTemporaryCredentials({ params: { RoleArn: roleArn, RoleSessionName: "rbb-kms-signer" } });
  return new KMSClient(cfg);
}

// SubjectPublicKeyInfo (DER) -> chave pública não comprimida (65 bytes, 0x04...)
export function publicKeyFromSpki(der) {
  const spki = asn1js.fromBER(der);
  const bitString = spki.result.valueBlock.value[1];
  return new Uint8Array(bitString.valueBlock.valueHexView);
}

// Assinatura DER (ECDSA) -> {r, s} com s normalizado (low-s, exigido pelo Ethereum)
export function rsFromDer(der) {
  const seq = asn1js.fromBER(der).result;
  const [rInt, sInt] = seq.valueBlock.value;
  let r = BigInt("0x" + Buffer.from(rInt.valueBlock.valueHexView).toString("hex"));
  let s = BigInt("0x" + Buffer.from(sInt.valueBlock.valueHexView).toString("hex"));
  if (s > SECP256K1_N / 2n) s = SECP256K1_N - s;
  return { r, s };
}

const hex32 = (n) => "0x" + n.toString(16).padStart(64, "0");

export class KmsSigner extends AbstractSigner {
  #client; #keyId; #address; #pubkey;
  constructor(keyId, { region = process.env.AWS_REGION || "sa-east-1", roleArn = process.env.RBB_KMS_ROLE_ARN, client = null } = {}, provider = null) {
    super(provider);
    this.#keyId = keyId;
    this.#client = client ?? kmsClient({ region, roleArn });
  }
  connect(provider) { const s = new KmsSigner(this.#keyId, {}, provider); s.#client = this.#client; s.#address = this.#address; s.#pubkey = this.#pubkey; return s; }

  async #loadPublicKey() {
    if (this.#pubkey) return;
    const { PublicKey } = await this.#client.send(new GetPublicKeyCommand({ KeyId: this.#keyId }));
    this.#pubkey = publicKeyFromSpki(PublicKey);
    this.#address = computeAddress("0x" + Buffer.from(this.#pubkey).toString("hex"));
  }
  async getAddress() { await this.#loadPublicKey(); return this.#address; }

  async #signDigest(digest) {
    await this.#loadPublicKey();
    const { Signature: der } = await this.#client.send(new SignCommand({
      KeyId: this.#keyId, Message: getBytes(digest), MessageType: "DIGEST", SigningAlgorithm: "ECDSA_SHA_256",
    }));
    const { r, s } = rsFromDer(der);
    // recupera v testando os dois candidatos contra o endereço da chave
    for (const v of [27, 28]) {
      const sig = Signature.from({ r: hex32(r), s: hex32(s), v });
      const rec = recoverAddress(digest, sig);
      if (rec.toLowerCase() === this.#address.toLowerCase()) return sig;
    }
    throw new Error("não foi possível recuperar v para a assinatura do KMS");
  }

  async signTransaction(tx) {
    const t = { ...tx };
    if (t.from != null) { if ((await resolveAddress(t.from)).toLowerCase() !== (await this.getAddress()).toLowerCase()) throw new Error("from não corresponde à chave KMS"); delete t.from; }
    const btx = Transaction.from(t);
    btx.signature = await this.#signDigest(btx.unsignedHash);
    return btx.serialized;
  }
  async signMessage(message) { return (await this.#signDigest(hashMessage(message))).serialized; }
  async signTypedData(domain, types, value) { return (await this.#signDigest(TypedDataEncoder.hash(domain, types, value))).serialized; }
}

export { keccak256 };
