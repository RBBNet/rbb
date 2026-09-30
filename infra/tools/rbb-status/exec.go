package main

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// Runner executa um script bash localmente ou em um nó via SSH (bash -s), sem exigir a CLI no nó.
type Runner struct {
	SSH  string // user@host; vazio = local
	Jump string // user@host de salto (nós privados)
}

func (r Runner) run(ctx context.Context, script string) (string, error) {
	var cmd *exec.Cmd
	if r.SSH == "" {
		cmd = exec.CommandContext(ctx, "bash", "-s")
	} else {
		args := []string{"-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=15", "-o", "BatchMode=yes"}
		if r.Jump != "" {
			args = append(args, "-J", r.Jump)
		}
		args = append(args, r.SSH, "bash", "-s")
		cmd = exec.CommandContext(ctx, "ssh", args...)
	}
	cmd.Stdin = strings.NewReader(script)
	var out, errb bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &errb
	if err := cmd.Run(); err != nil {
		return out.String(), fmt.Errorf("%w: %s", err, strings.TrimSpace(errb.String()))
	}
	return out.String(), nil
}

func (r Runner) String() string {
	if r.SSH == "" {
		return "local"
	}
	if r.Jump != "" {
		return r.SSH + " (via " + r.Jump + ")"
	}
	return r.SSH
}

const defaultTimeout = 4 * time.Second

// probeScript gera o script que testa TCP em cada destino e imprime "OPEN addr" ou "CLOSED addr".
func probeScript(addrs []string, timeout time.Duration) string {
	var b strings.Builder
	secs := int(timeout.Seconds())
	if secs < 1 {
		secs = 1
	}
	for _, a := range addrs {
		host, port := splitHostPort(a)
		fmt.Fprintf(&b, "if timeout %d bash -c 'exec 3<>/dev/tcp/%s/%s' 2>/dev/null; then echo OPEN %s; else echo CLOSED %s; fi\n", secs, host, port, a, a)
	}
	return b.String()
}

func splitHostPort(a string) (string, string) {
	i := strings.LastIndex(a, ":")
	if i < 0 {
		return a, ""
	}
	return a[:i], a[i+1:]
}

// parseProbe lê a saída do probeScript.
func parseProbe(out string) map[string]bool {
	res := map[string]bool{}
	for _, line := range strings.Split(out, "\n") {
		f := strings.Fields(line)
		if len(f) != 2 {
			continue
		}
		res[f[1]] = f[0] == "OPEN"
	}
	return res
}
