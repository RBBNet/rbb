package main

import (
	"encoding/json"
	"strings"
)

// Prometheus /api/v1/targets
type promTargets struct {
	Data struct {
		ActiveTargets []struct {
			Labels    map[string]string `json:"labels"`
			Health    string            `json:"health"`
			LastError string            `json:"lastError"`
			ScrapeURL string            `json:"scrapeUrl"`
		} `json:"activeTargets"`
	} `json:"data"`
}

type FedStatus struct {
	Org    string
	Target string
	Health string // up | down
	Reason string // ok | certificado não instalado | firewall fechado | outro erro
}

func classifyFederation(health, lastError string) string {
	if health == "up" {
		return "ok"
	}
	e := strings.ToLower(lastError)
	switch {
	case strings.Contains(e, "400"):
		return "porta aberta, certificado não instalado"
	case strings.Contains(e, "deadline"), strings.Contains(e, "timeout"), strings.Contains(e, "i/o timeout"):
		return "firewall fechado"
	case strings.Contains(e, "refused"):
		return "porta fechada (conexão recusada)"
	case strings.Contains(e, "certificate"), strings.Contains(e, "tls"):
		return "erro de TLS: " + lastError
	default:
		return lastError
	}
}

func parseFederation(out string, job string) ([]FedStatus, error) {
	var t promTargets
	if err := json.Unmarshal([]byte(strings.TrimSpace(out)), &t); err != nil {
		return nil, err
	}
	var res []FedStatus
	for _, a := range t.Data.ActiveTargets {
		if a.Labels["job"] != job {
			continue
		}
		res = append(res, FedStatus{
			Org:    a.Labels["organization"],
			Target: strings.TrimSuffix(strings.TrimPrefix(strings.TrimPrefix(a.ScrapeURL, "https://"), "http://"), "/federate"),
			Health: a.Health,
			Reason: classifyFederation(a.Health, a.LastError),
		})
	}
	return res, nil
}
