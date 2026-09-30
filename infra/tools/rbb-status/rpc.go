package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"

	"golang.org/x/crypto/sha3"
)

// curlScript devolve um script que faz a chamada JSON-RPC via curl e imprime a resposta.
func rpcScript(url, method string, params string) string {
	body := fmt.Sprintf(`{"jsonrpc":"2.0","method":"%s","params":%s,"id":1}`, method, params)
	return fmt.Sprintf("curl -s -m 20 -X POST -H 'Content-Type: application/json' --data '%s' '%s'\n", body, url)
}

type rpcResp struct {
	Result json.RawMessage `json:"result"`
	Error  *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func parseRPC(out string) (json.RawMessage, error) {
	var r rpcResp
	if err := json.Unmarshal([]byte(strings.TrimSpace(out)), &r); err != nil {
		return nil, fmt.Errorf("resposta RPC inválida: %.120s", out)
	}
	if r.Error != nil {
		return nil, fmt.Errorf("RPC: %s", r.Error.Message)
	}
	return r.Result, nil
}

// admin_peers
type peer struct {
	ID      string `json:"id"` // chave pública (0x + 128 hex)
	Network struct {
		RemoteAddress string `json:"remoteAddress"`
		Inbound       bool   `json:"inbound"`
	} `json:"network"`
}

func parsePeers(raw json.RawMessage) ([]peer, error) {
	var ps []peer
	return ps, json.Unmarshal(raw, &ps)
}

// keccak256 selector de função
func selector(sig string) []byte {
	h := sha3.NewLegacyKeccak256()
	h.Write([]byte(sig))
	return h.Sum(nil)[:4]
}

// isNodeActiveCalldata codifica NodeRulesV2.isNodeActive(bytes32 enodeHigh, bytes32 enodeLow)
func isNodeActiveCalldata(pubkey string) (string, error) {
	k := strings.ToLower(strings.TrimPrefix(pubkey, "0x"))
	if len(k) != 128 {
		return "", fmt.Errorf("chave pública inválida (%d hex, esperado 128)", len(k))
	}
	if _, err := hex.DecodeString(k); err != nil {
		return "", err
	}
	return "0x" + hex.EncodeToString(selector("isNodeActive(bytes32,bytes32)")) + k[:64] + k[64:], nil
}

// ethCallScript monta eth_call para o contrato e calldata.
func ethCallScript(url, to, data string) string {
	params := fmt.Sprintf(`[{"to":"%s","data":"%s"},"latest"]`, to, data)
	return rpcScript(url, "eth_call", params)
}

func decodeBool(raw json.RawMessage) (bool, error) {
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return false, err
	}
	s = strings.TrimPrefix(s, "0x")
	if len(s) != 64 {
		return false, fmt.Errorf("retorno inesperado: 0x%s", s)
	}
	return strings.TrimLeft(s, "0") == "1", nil
}

func decodeHexInt(raw json.RawMessage) (int64, error) {
	var s string
	if err := json.Unmarshal(raw, &s); err != nil {
		return 0, err
	}
	var v int64
	_, err := fmt.Sscanf(strings.TrimPrefix(s, "0x"), "%x", &v)
	return v, err
}
