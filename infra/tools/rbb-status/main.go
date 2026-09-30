// rbb-status: mostra, do ponto de vista de um partícipe da Rede Blockchain Brasil, o estado da
// integração dos seus nós com a rede: quais organizações já liberaram firewall (passo 9 do roteiro
// de adição de nós), quem já aceita a federação do Prometheus, com quem os nós estão conectados
// e se os nós já foram permissionados on chain (NodeRulesV2.isNodeActive).
//
// Os testes de rede precisam sair dos próprios nós (as outras organizações liberam os IPs dos nós,
// não o da sua estação); por isso cada comando pode rodar localmente no nó ou via SSH (--ssh).
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sort"
	"strings"
	"text/tabwriter"
	"time"
)

const version = "0.1.0"

func usage() {
	fmt.Fprintf(os.Stderr, `rbb-status %s — estado da integração de um partícipe com a RBB

Uso: rbb-status <comando> [opções]

Comandos:
  firewall       testa TCP na porta P2P/8443 dos nós das outras organizações (a partir do nó)
  peers          admin_peers do nó, com organização e nome de cada peer (via nodes.json)
  federation     saúde dos alvos federados do Prometheus (job rbb-federado)
  permissioning  NodeRulesV2.isNodeActive para os nós da organização
  report         tudo acima, a partir de um arquivo de configuração (--config)

Opções comuns:
  --nodes <nodes.json>   documentação de nós (RBBNet/participantes/<rede>/nodes.json)
  --org <nome>           nome da organização como no nodes.json (ex.: BNDES)
  --ssh user@host        executa no nó via SSH (bash -s); --jump user@host para nós privados
  --json                 saída em JSON

Exemplos:
  rbb-status firewall --nodes lab/nodes.json --org ACIEG --role validator --ssh ubuntu@201.0.0.1
  rbb-status peers --nodes lab/nodes.json --ssh ubuntu@201.0.0.1
  rbb-status federation --ssh ubuntu@10.0.1.61 --jump ubuntu@201.0.0.1
  rbb-status permissioning --nodes lab/nodes.json --org ACIEG --node-rules 0x805c... --ssh ubuntu@201.0.0.1
  rbb-status report --config rbb-status.json
`, version)
}

type common struct {
	nodes, org, ssh, jump string
	jsonOut               bool
}

func addCommon(fs *flag.FlagSet, c *common) {
	fs.StringVar(&c.nodes, "nodes", "nodes.json", "caminho do nodes.json")
	fs.StringVar(&c.org, "org", "", "nome da organização (como no nodes.json)")
	fs.StringVar(&c.ssh, "ssh", "", "executar via SSH em user@host")
	fs.StringVar(&c.jump, "jump", "", "host de salto SSH (user@host)")
	fs.BoolVar(&c.jsonOut, "json", false, "saída em JSON")
}

func die(err error) {
	fmt.Fprintln(os.Stderr, "erro:", err)
	os.Exit(1)
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()
	switch os.Args[1] {
	case "firewall":
		cmdFirewall(ctx, os.Args[2:])
	case "peers":
		cmdPeers(ctx, os.Args[2:])
	case "federation":
		cmdFederation(ctx, os.Args[2:])
	case "permissioning":
		cmdPermissioning(ctx, os.Args[2:])
	case "report":
		cmdReport(ctx, os.Args[2:])
	case "version", "--version", "-v":
		fmt.Println("rbb-status", version)
	default:
		usage()
		os.Exit(2)
	}
}

// ---------------------------------------------------------------- firewall
type FirewallResult struct {
	Role    string           `json:"role"`
	From    string           `json:"from"`
	Targets []FirewallTarget `json:"targets"`
}
type FirewallTarget struct {
	Org  string `json:"organization"`
	Node string `json:"node"`
	Type string `json:"type"`
	Addr string `json:"address"`
	Open bool   `json:"open"`
}

func runFirewall(ctx context.Context, orgs []Organization, org, role string, r Runner) (FirewallResult, error) {
	targets := targetsForRole(orgs, org, role)
	addrs := make([]string, 0, len(targets))
	for _, t := range targets {
		addrs = append(addrs, t.Addr)
	}
	res := FirewallResult{Role: role, From: r.String()}
	if len(addrs) == 0 {
		return res, nil
	}
	out, err := r.run(ctx, probeScript(addrs, defaultTimeout))
	if err != nil && out == "" {
		return res, err
	}
	open := parseProbe(out)
	for _, t := range targets {
		res.Targets = append(res.Targets, FirewallTarget{Org: t.Org, Node: t.Node, Type: t.Type, Addr: t.Addr, Open: open[t.Addr]})
	}
	return res, nil
}

func cmdFirewall(ctx context.Context, args []string) {
	fs := flag.NewFlagSet("firewall", flag.ExitOnError)
	var c common
	addCommon(fs, &c)
	role := fs.String("role", "validator", "papel do nó de origem: validator | boot | prometheus")
	fs.Parse(args)
	orgs, err := loadNodes(c.nodes)
	if err != nil {
		die(err)
	}
	if c.org == "" {
		die(fmt.Errorf("--org é obrigatório"))
	}
	res, err := runFirewall(ctx, orgs, c.org, *role, Runner{SSH: c.ssh, Jump: c.jump})
	if err != nil {
		die(err)
	}
	if c.jsonOut {
		printJSON(res)
		return
	}
	printFirewall(res)
}

func printFirewall(res FirewallResult) {
	fmt.Printf("Firewall — a partir do nosso %s (%s): destinos do passo 9 do roteiro\n", res.Role, res.From)
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "  ORGANIZAÇÃO\tNÓ\tENDEREÇO\tESTADO")
	open := 0
	for _, t := range res.Targets {
		st := "fechado"
		if t.Open {
			st = "ABERTO"
			open++
		}
		fmt.Fprintf(w, "  %s\t%s\t%s\t%s\n", t.Org, t.Node, t.Addr, st)
	}
	w.Flush()
	fmt.Printf("  %d de %d destinos abertos\n\n", open, len(res.Targets))
}

// ---------------------------------------------------------------- peers
type PeerResult struct {
	From  string     `json:"from"`
	Peers []PeerInfo `json:"peers"`
}
type PeerInfo struct {
	Org     string `json:"organization"`
	Node    string `json:"node"`
	Type    string `json:"type"`
	Remote  string `json:"remote"`
	Inbound bool   `json:"inbound"`
}

func runPeers(ctx context.Context, orgs []Organization, rpcURL string, r Runner) (PeerResult, error) {
	res := PeerResult{From: r.String()}
	out, err := r.run(ctx, rpcScript(rpcURL, "admin_peers", "[]"))
	if err != nil {
		return res, err
	}
	raw, err := parseRPC(out)
	if err != nil {
		return res, err
	}
	ps, err := parsePeers(raw)
	if err != nil {
		return res, err
	}
	idx := pubkeyIndex(orgs)
	for _, p := range ps {
		k := strings.ToLower(strings.TrimPrefix(p.ID, "0x"))
		info := PeerInfo{Org: "?", Node: "?", Remote: p.Network.RemoteAddress, Inbound: p.Network.Inbound}
		if t, ok := idx[k]; ok {
			info.Org, info.Node, info.Type = t.Org, t.Node, t.Type
		}
		res.Peers = append(res.Peers, info)
	}
	return res, nil
}

func cmdPeers(ctx context.Context, args []string) {
	fs := flag.NewFlagSet("peers", flag.ExitOnError)
	var c common
	addCommon(fs, &c)
	rpcURL := fs.String("rpc", "http://127.0.0.1:8545", "URL JSON-RPC do nó (a partir de onde o comando roda)")
	fs.Parse(args)
	orgs, err := loadNodes(c.nodes)
	if err != nil {
		die(err)
	}
	res, err := runPeers(ctx, orgs, *rpcURL, Runner{SSH: c.ssh, Jump: c.jump})
	if err != nil {
		die(err)
	}
	if c.jsonOut {
		printJSON(res)
		return
	}
	printPeers(res)
}

func printPeers(res PeerResult) {
	fmt.Printf("Peers conectados (%s): %d\n", res.From, len(res.Peers))
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	for _, p := range res.Peers {
		dir := "saída"
		if p.Inbound {
			dir = "entrada"
		}
		fmt.Fprintf(w, "  %s\t%s\t%s\t%s\t%s\n", p.Org, p.Node, p.Type, p.Remote, dir)
	}
	w.Flush()
	fmt.Println()
}

// ---------------------------------------------------------------- federation
type FederationResult struct {
	From    string      `json:"from"`
	Targets []FedStatus `json:"targets"`
}

func runFederation(ctx context.Context, promURL, job string, r Runner) (FederationResult, error) {
	res := FederationResult{From: r.String()}
	out, err := r.run(ctx, fmt.Sprintf("curl -s -m 20 '%s/api/v1/targets'\n", strings.TrimSuffix(promURL, "/")))
	if err != nil {
		return res, err
	}
	res.Targets, err = parseFederation(out, job)
	sort.Slice(res.Targets, func(i, j int) bool { return res.Targets[i].Org < res.Targets[j].Org })
	return res, err
}

func cmdFederation(ctx context.Context, args []string) {
	fs := flag.NewFlagSet("federation", flag.ExitOnError)
	var c common
	addCommon(fs, &c)
	promURL := fs.String("prometheus", "http://127.0.0.1:9090", "URL do Prometheus (a partir de onde o comando roda)")
	job := fs.String("job", "rbb-federado", "nome do job federado")
	fs.Parse(args)
	res, err := runFederation(ctx, *promURL, *job, Runner{SSH: c.ssh, Jump: c.jump})
	if err != nil {
		die(err)
	}
	if c.jsonOut {
		printJSON(res)
		return
	}
	printFederation(res)
}

func printFederation(res FederationResult) {
	fmt.Printf("Federação do Prometheus (%s): alvos do job rbb-federado\n", res.From)
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "  ORGANIZAÇÃO\tALVO\tSAÚDE\tSITUAÇÃO")
	up := 0
	for _, t := range res.Targets {
		if t.Health == "up" {
			up++
		}
		fmt.Fprintf(w, "  %s\t%s\t%s\t%s\n", t.Org, t.Target, t.Health, t.Reason)
	}
	w.Flush()
	fmt.Printf("  %d de %d organizações aceitam nosso certificado\n\n", up, len(res.Targets))
}

// ---------------------------------------------------------------- permissioning
type PermissioningResult struct {
	From     string     `json:"from"`
	Contract string     `json:"nodeRulesV2"`
	Block    int64      `json:"block"`
	Syncing  bool       `json:"syncing"`
	Nodes    []NodePerm `json:"nodes"`
}
type NodePerm struct {
	Node   string `json:"node"`
	Type   string `json:"type"`
	Active bool   `json:"active"`
	Error  string `json:"error,omitempty"`
}

func runPermissioning(ctx context.Context, nodes []Node, rpcURL, contract string, r Runner) (PermissioningResult, error) {
	res := PermissioningResult{From: r.String(), Contract: contract}
	// altura e sincronização do nó consultado (o resultado vale para o bloco em que ele está)
	if out, err := r.run(ctx, rpcScript(rpcURL, "eth_blockNumber", "[]")); err == nil {
		if raw, err := parseRPC(out); err == nil {
			res.Block, _ = decodeHexInt(raw)
		}
	}
	if out, err := r.run(ctx, rpcScript(rpcURL, "eth_syncing", "[]")); err == nil {
		if raw, err := parseRPC(out); err == nil {
			res.Syncing = strings.TrimSpace(string(raw)) != "false"
		}
	}
	for _, n := range nodes {
		if n.NodeType == "prometheus" || n.PubKey == "" {
			continue
		}
		np := NodePerm{Node: n.Name, Type: n.NodeType}
		data, err := isNodeActiveCalldata(n.PubKey)
		if err != nil {
			np.Error = err.Error()
			res.Nodes = append(res.Nodes, np)
			continue
		}
		out, err := r.run(ctx, ethCallScript(rpcURL, contract, data))
		if err != nil {
			np.Error = err.Error()
		} else if raw, err := parseRPC(out); err != nil {
			np.Error = err.Error()
		} else if np.Active, err = decodeBool(raw); err != nil {
			np.Error = err.Error()
		}
		res.Nodes = append(res.Nodes, np)
	}
	return res, nil
}

func cmdPermissioning(ctx context.Context, args []string) {
	fs := flag.NewFlagSet("permissioning", flag.ExitOnError)
	var c common
	addCommon(fs, &c)
	rpcURL := fs.String("rpc", "http://127.0.0.1:8545", "URL JSON-RPC de um nó sincronizado")
	contract := fs.String("node-rules", "", "endereço do NodeRulesV2Impl (participantes/<rede>/contratos.md)")
	var pubkeys multiFlag
	fs.Var(&pubkeys, "pubkey", "chave pública a consultar (repetível); padrão: nós da organização no nodes.json")
	fs.Parse(args)
	if *contract == "" {
		die(fmt.Errorf("--node-rules é obrigatório"))
	}
	var nodes []Node
	if len(pubkeys) > 0 {
		for i, k := range pubkeys {
			nodes = append(nodes, Node{Name: fmt.Sprintf("pubkey%d", i+1), NodeType: "?", PubKey: k})
		}
	} else {
		orgs, err := loadNodes(c.nodes)
		if err != nil {
			die(err)
		}
		if c.org == "" {
			die(fmt.Errorf("--org é obrigatório (ou informe --pubkey)"))
		}
		nodes = ourNodes(orgs, c.org)
		if len(nodes) == 0 {
			die(fmt.Errorf("organização %q não encontrada no nodes.json; use --pubkey", c.org))
		}
	}
	res, err := runPermissioning(ctx, nodes, *rpcURL, *contract, Runner{SSH: c.ssh, Jump: c.jump})
	if err != nil {
		die(err)
	}
	if c.jsonOut {
		printJSON(res)
		return
	}
	printPermissioning(res)
}

func printPermissioning(res PermissioningResult) {
	sync := ""
	if res.Syncing {
		sync = " (ainda sincronizando: o resultado reflete o bloco atual do nó, não a ponta da rede)"
	}
	fmt.Printf("Permissionamento on chain (%s, bloco %d%s)\n  NodeRulesV2: %s\n", res.From, res.Block, sync, res.Contract)
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	for _, n := range res.Nodes {
		st := "NÃO permissionado"
		if n.Active {
			st = "permissionado"
		}
		if n.Error != "" {
			st = "erro: " + n.Error
		}
		fmt.Fprintf(w, "  %s\t%s\t%s\n", n.Node, n.Type, st)
	}
	w.Flush()
	fmt.Println()
}

// ---------------------------------------------------------------- report
type Config struct {
	Org       string          `json:"org"`
	NodesJSON string          `json:"nodes_json"`
	NodeRules string          `json:"node_rules_v2"`
	Hosts     map[string]Host `json:"hosts"`
	OurNodes  []Node          `json:"our_nodes,omitempty"` // opcional: quando a organização ainda não está no nodes.json
}
type Host struct {
	Role string `json:"role"` // validator | boot | prometheus | rpc
	SSH  string `json:"ssh"`
	Jump string `json:"jump,omitempty"`
}

func cmdReport(ctx context.Context, args []string) {
	fs := flag.NewFlagSet("report", flag.ExitOnError)
	cfgPath := fs.String("config", "rbb-status.json", "arquivo de configuração")
	jsonOut := fs.Bool("json", false, "saída em JSON")
	fs.Parse(args)
	b, err := os.ReadFile(*cfgPath)
	if err != nil {
		die(err)
	}
	var cfg Config
	if err := json.Unmarshal(b, &cfg); err != nil {
		die(err)
	}
	orgs, err := loadNodes(cfg.NodesJSON)
	if err != nil {
		die(err)
	}
	report := map[string]any{"organization": cfg.Org, "generated_at": time.Now().Format(time.RFC3339)}
	names := make([]string, 0, len(cfg.Hosts))
	for n := range cfg.Hosts {
		names = append(names, n)
	}
	sort.Strings(names)
	if !*jsonOut {
		fmt.Printf("== rbb-status: %s — %s\n\n", cfg.Org, time.Now().Format("2006-01-02 15:04"))
	}
	var rpcRunner *Runner
	for _, name := range names {
		h := cfg.Hosts[name]
		r := Runner{SSH: h.SSH, Jump: h.Jump}
		switch h.Role {
		case "validator", "boot":
			fw, err := runFirewall(ctx, orgs, cfg.Org, h.Role, r)
			if err != nil {
				fmt.Fprintf(os.Stderr, "%s: %v\n", name, err)
			}
			pr, perr := runPeers(ctx, orgs, "http://127.0.0.1:8545", r)
			if perr != nil {
				fmt.Fprintf(os.Stderr, "%s: %v\n", name, perr)
			}
			report[name] = map[string]any{"firewall": fw, "peers": pr}
			if !*jsonOut {
				fmt.Printf("[%s]\n", name)
				printFirewall(fw)
				printPeers(pr)
			}
			if rpcRunner == nil && h.Role == "boot" {
				rr := r
				rpcRunner = &rr
			}
		case "prometheus":
			fd, err := runFederation(ctx, "http://127.0.0.1:9090", "rbb-federado", r)
			if err != nil {
				fmt.Fprintf(os.Stderr, "%s: %v\n", name, err)
			}
			report[name] = fd
			if !*jsonOut {
				fmt.Printf("[%s]\n", name)
				printFederation(fd)
			}
		case "rpc":
			rr := r
			rpcRunner = &rr
		}
	}
	if cfg.NodeRules != "" && rpcRunner != nil {
		nodes := cfg.OurNodes
		if len(nodes) == 0 {
			nodes = ourNodes(orgs, cfg.Org)
		}
		pm, err := runPermissioning(ctx, nodes, "http://127.0.0.1:8545", cfg.NodeRules, *rpcRunner)
		if err != nil {
			fmt.Fprintf(os.Stderr, "permissionamento: %v\n", err)
		}
		report["permissioning"] = pm
		if !*jsonOut {
			printPermissioning(pm)
		}
	}
	if *jsonOut {
		printJSON(report)
	}
}

// ---------------------------------------------------------------- util
type multiFlag []string

func (m *multiFlag) String() string     { return strings.Join(*m, ",") }
func (m *multiFlag) Set(v string) error { *m = append(*m, v); return nil }

func printJSON(v any) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(v); err != nil {
		die(err)
	}
}
