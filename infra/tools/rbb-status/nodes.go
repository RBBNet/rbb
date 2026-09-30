package main

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"strings"
)

// Estruturas do nodes.json (RBBNet/participantes/<rede>/nodes.json, nodes.schema.json)
type Node struct {
	Name              string   `json:"name"`
	NodeType          string   `json:"nodeType"`
	PubKey            string   `json:"pubKey"`
	HostNames         []string `json:"hostNames"`
	IPAddresses       []string `json:"ipAddresses"`
	Port              int      `json:"port"`
	ID                string   `json:"id"`
	DeploymentStatus  string   `json:"deploymentStatus"`
	OperationalStatus string   `json:"operationalStatus"`
}

type Organization struct {
	Organization string `json:"organization"`
	Nodes        []Node `json:"nodes"`
}

func loadNodes(path string) ([]Organization, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var orgs []Organization
	if err := json.Unmarshal(b, &orgs); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	return orgs, nil
}

func (n Node) active() bool {
	return n.DeploymentStatus == "deployed" && n.OperationalStatus == "active"
}

func isPrivateIP(ip string) bool {
	p := net.ParseIP(ip)
	return p != nil && p.IsPrivate()
}

// Target é um destino a testar (organização, nó, ip:porta).
type Target struct {
	Org  string
	Node string
	Type string
	Addr string // ip:porta
}

// targetsForRole devolve, conforme o passo 9 do roteiro de adição de nós, os nós das OUTRAS
// organizações que o nosso nó do papel indicado precisa alcançar:
//
//	validator  -> validators das outras organizações
//	boot       -> boots, observer-boots e writers de parceiros (IP público) das outras organizações
//	prometheus -> Prometheus (porta 8443) das outras organizações
func targetsForRole(orgs []Organization, ourOrg, role string) []Target {
	var out []Target
	for _, o := range orgs {
		if strings.EqualFold(o.Organization, ourOrg) {
			continue
		}
		for _, n := range o.Nodes {
			if !n.active() || len(n.IPAddresses) == 0 {
				continue
			}
			ok := false
			switch role {
			case "validator":
				ok = n.NodeType == "validator"
			case "boot":
				ok = n.NodeType == "boot" || n.NodeType == "observer-boot" || (n.NodeType == "writer" && !isPrivateIP(n.IPAddresses[0]))
			case "prometheus":
				ok = n.NodeType == "prometheus" && n.Port == 8443
			}
			if !ok || isPrivateIP(n.IPAddresses[0]) {
				continue
			}
			out = append(out, Target{Org: o.Organization, Node: n.Name, Type: n.NodeType, Addr: fmt.Sprintf("%s:%d", n.IPAddresses[0], n.Port)})
		}
	}
	return out
}

// pubkeyIndex mapeia chave pública (sem 0x, minúsculas) -> (org, nó)
func pubkeyIndex(orgs []Organization) map[string]Target {
	idx := map[string]Target{}
	for _, o := range orgs {
		for _, n := range o.Nodes {
			if n.PubKey == "" {
				continue
			}
			k := strings.ToLower(strings.TrimPrefix(n.PubKey, "0x"))
			idx[k] = Target{Org: o.Organization, Node: n.Name, Type: n.NodeType}
		}
	}
	return idx
}

func ourNodes(orgs []Organization, ourOrg string) []Node {
	for _, o := range orgs {
		if strings.EqualFold(o.Organization, ourOrg) {
			return o.Nodes
		}
	}
	return nil
}
