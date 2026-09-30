package main

import (
	"context"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const sampleNodes = `[
 {"organization":"BNDES","nodes":[
   {"name":"validator01","nodeType":"validator","pubKey":"0x` + "aa" + `","ipAddresses":["200.225.100.83"],"port":60000,"deploymentStatus":"deployed","operationalStatus":"active"},
   {"name":"boot01","nodeType":"boot","pubKey":"0xbb","ipAddresses":["200.225.100.83"],"port":60001,"deploymentStatus":"deployed","operationalStatus":"active"},
   {"name":"writer01","nodeType":"writer","pubKey":"0xcc","ipAddresses":["172.17.64.34"],"port":60606,"deploymentStatus":"deployed","operationalStatus":"active"},
   {"name":"prometheus02","nodeType":"prometheus","ipAddresses":["200.225.100.83"],"port":8443,"deploymentStatus":"deployed","operationalStatus":"active"},
   {"name":"validator09","nodeType":"validator","pubKey":"0xdd","ipAddresses":["200.225.100.9"],"port":60000,"deploymentStatus":"retired","operationalStatus":"inactive"}]},
 {"organization":"PLEXOS","nodes":[
   {"name":"writer01","nodeType":"writer","pubKey":"0xee","ipAddresses":["3.228.137.95"],"port":30303,"deploymentStatus":"deployed","operationalStatus":"active"}]},
 {"organization":"ACIEG","nodes":[
   {"name":"validator01","nodeType":"validator","pubKey":"0xff","ipAddresses":["201.23.73.56"],"port":30303,"deploymentStatus":"provisioned","operationalStatus":"active"}]}
]`

func writeSample(t *testing.T) string {
	t.Helper()
	p := filepath.Join(t.TempDir(), "nodes.json")
	if err := os.WriteFile(p, []byte(sampleNodes), 0o644); err != nil {
		t.Fatal(err)
	}
	return p
}

func TestTargetsForRole(t *testing.T) {
	orgs, err := loadNodes(writeSample(t))
	if err != nil {
		t.Fatal(err)
	}
	v := targetsForRole(orgs, "ACIEG", "validator")
	if len(v) != 1 || v[0].Addr != "200.225.100.83:60000" {
		t.Fatalf("validators: %+v", v) // exclui o retired e a própria organização
	}
	b := targetsForRole(orgs, "ACIEG", "boot")
	if len(b) != 2 { // boot do BNDES + writer público do PLEXOS; writer interno do BNDES fica de fora
		t.Fatalf("boots: %+v", b)
	}
	p := targetsForRole(orgs, "ACIEG", "prometheus")
	if len(p) != 1 || p[0].Addr != "200.225.100.83:8443" {
		t.Fatalf("prometheus: %+v", p)
	}
}

func TestProbeScriptAndParse(t *testing.T) {
	s := probeScript([]string{"1.2.3.4:30303"}, defaultTimeout)
	if !strings.Contains(s, "/dev/tcp/1.2.3.4/30303") {
		t.Fatal(s)
	}
	r := parseProbe("OPEN 1.2.3.4:30303\nCLOSED 5.6.7.8:1\nlixo\n")
	if !r["1.2.3.4:30303"] || r["5.6.7.8:1"] {
		t.Fatalf("%v", r)
	}
}

func TestIsNodeActiveCalldata(t *testing.T) {
	pk := "0x" + strings.Repeat("ab", 32) + strings.Repeat("cd", 32)
	d, err := isNodeActiveCalldata(pk)
	if err != nil {
		t.Fatal(err)
	}
	sel := hex.EncodeToString(selector("isNodeActive(bytes32,bytes32)"))
	if !strings.HasPrefix(d, "0x"+sel) || len(d) != 2+8+128 {
		t.Fatalf("calldata %s", d)
	}
	if _, err := isNodeActiveCalldata("0x1234"); err == nil {
		t.Fatal("chave curta deveria falhar")
	}
}

func TestDecodeBool(t *testing.T) {
	ok, err := decodeBool([]byte(`"0x0000000000000000000000000000000000000000000000000000000000000001"`))
	if err != nil || !ok {
		t.Fatal(err, ok)
	}
	ok, _ = decodeBool([]byte(`"0x0000000000000000000000000000000000000000000000000000000000000000"`))
	if ok {
		t.Fatal("esperado false")
	}
}

func TestParseFederation(t *testing.T) {
	out := `{"data":{"activeTargets":[
	 {"labels":{"job":"rbb-federado","organization":"RNP"},"health":"down","lastError":"server returned HTTP status 400 Bad Request","scrapeUrl":"https://1.1.1.1:8443/federate"},
	 {"labels":{"job":"rbb-federado","organization":"TCU"},"health":"down","lastError":"Get \"https://2.2.2.2:8443/federate\": context deadline exceeded","scrapeUrl":"https://2.2.2.2:8443/federate"},
	 {"labels":{"job":"rbb-federado","organization":"BNDES"},"health":"up","lastError":"","scrapeUrl":"https://3.3.3.3:8443/federate"},
	 {"labels":{"job":"rbb","node":"boot01"},"health":"up","lastError":"","scrapeUrl":"http://10.0.0.1:9545/metrics"}]}}`
	res, err := parseFederation(out, "rbb-federado")
	if err != nil {
		t.Fatal(err)
	}
	if len(res) != 3 {
		t.Fatalf("%d alvos", len(res))
	}
	want := map[string]string{"RNP": "porta aberta, certificado não instalado", "TCU": "firewall fechado", "BNDES": "ok"}
	for _, r := range res {
		if want[r.Org] != r.Reason {
			t.Errorf("%s: %q", r.Org, r.Reason)
		}
	}
}

func TestParsePeersAndIndex(t *testing.T) {
	orgs, _ := loadNodes(writeSample(t))
	idx := pubkeyIndex(orgs)
	if idx["bb"].Org != "BNDES" || idx["bb"].Node != "boot01" {
		t.Fatalf("%+v", idx["bb"])
	}
	raw, err := parseRPC(`{"jsonrpc":"2.0","id":1,"result":[{"id":"0xbb","network":{"remoteAddress":"200.225.100.83:60001","inbound":false}}]}`)
	if err != nil {
		t.Fatal(err)
	}
	ps, err := parsePeers(raw)
	if err != nil || len(ps) != 1 || ps[0].Network.RemoteAddress != "200.225.100.83:60001" {
		t.Fatalf("%v %+v", err, ps)
	}
}

func TestRunnerLocal(t *testing.T) {
	out, err := Runner{}.run(context.Background(), "echo OPEN 127.0.0.1:1\n")
	if err != nil || !parseProbe(out)["127.0.0.1:1"] {
		t.Fatal(err, out)
	}
}
