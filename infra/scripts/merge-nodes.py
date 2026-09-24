#!/usr/bin/env python3
"""Insere ou substitui a entrada de uma organização em um nodes.json da RBB
PRESERVANDO a formatação original do arquivo (tabs/espaços, quebras de linha),
para que o pull request no repositório participantes mostre apenas a alteração.

Uso: merge-nodes.py <nodes.json atual> <entrada-da-organizacao.json> <saida.json>
"""
import json
import re
import sys

cur_path, ours_path, out_path = sys.argv[1:4]
raw = open(cur_path, encoding="utf-8").read()
ours = json.load(open(ours_path, encoding="utf-8"))
data = json.loads(raw)

# unidade de indentação do arquivo: espaço em branco antes do primeiro "{" de organização
m = re.search(r"\n([ \t]+)\{", raw)
unit = m.group(1) if m else "\t"
nl = "\r\n" if "\r\n" in raw else "\n"


def fmt(entry):
    txt = json.dumps(entry, indent=unit, ensure_ascii=False)
    return nl.join(unit + line for line in txt.split("\n"))


idx = next((i for i, o in enumerate(data) if o.get("organization") == ours["organization"]), None)
if idx is None:
    close = raw.rstrip().rfind("]")
    head = raw[:close].rstrip()
    if not head.endswith("["):
        head += ","
    out = head + nl + fmt(ours) + nl + "]" + nl
else:
    # substitui o bloco textual da organização existente (do "{" da entrada ao "}" correspondente)
    pos = [mm.start() for mm in re.finditer(r'"organization"', raw)][idx]
    start = raw.rfind("{", 0, pos)
    depth, i = 0, start
    while i < len(raw):
        c = raw[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    out = raw[:start] + fmt(ours).lstrip() + raw[i + 1:]

json.loads(out)  # valida o resultado
open(out_path, "w", encoding="utf-8").write(out)
