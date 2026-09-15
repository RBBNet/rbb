#!/usr/bin/env bash
# Bootstrap do nó prometheus<NN> da RBB. Chamado por rbb-node-setup.
# Cria estrutura em ${DATA_MOUNT}/prometheus e sobe Prometheus + NGINX (mTLS).
set -euo pipefail

# shellcheck disable=SC1091
source /etc/rbb/node.env

PROM_HOME="${DATA_MOUNT}/prometheus"
mkdir -p "${PROM_HOME}"/{rules,certs,logs}
cp -f /etc/rbb/prometheus/prometheus.yml "${PROM_HOME}/prometheus.yml"
cp -f /etc/rbb/prometheus/nginx.conf "${PROM_HOME}/nginx.conf"
cp -f /etc/rbb/prometheus/docker-compose.yml "${PROM_HOME}/docker-compose.yml"

# Regras de alerta/métricas derivadas publicadas em RBBNet/start-network (examples/prometheus).
SN="${DATA_MOUNT}/start-network/examples/prometheus"
for f in rules-blockchain.yml rules-rbb.yml rules-rbb-lab.yml; do
  if [[ -f "${SN}/${f}" ]]; then
    cp -f "${SN}/${f}" "${PROM_HOME}/rules/${f}"
  else
    [[ -f "${PROM_HOME}/rules/${f}" ]] || printf 'groups: []\n' > "${PROM_HOME}/rules/${f}"
  fi
done

# Certificado autoassinado do servidor (roteiro_prometheus_nginx.md, passo 2). Válido por 2 anos.
if [[ ! -f "${PROM_HOME}/certs/chave-privada.key" ]]; then
  CN="${PUBLIC_IP:-${PRIVATE_IP}}"
  openssl genrsa -out "${PROM_HOME}/certs/chave-privada.key" 4096
  openssl req -new -key "${PROM_HOME}/certs/chave-privada.key" \
    -out "${PROM_HOME}/certs/pedido.csr" \
    -subj "/C=BR/O=${ORGANIZATION}-RBB/CN=${CN}"
  openssl x509 -req -days 730 -in "${PROM_HOME}/certs/pedido.csr" \
    -signkey "${PROM_HOME}/certs/chave-privada.key" \
    -out "${PROM_HOME}/certs/certificado.pem"
fi
# client.pem: certificados dos demais partícipes (RBBNet/participantes/<rede>/certificados).
# Começa com o próprio certificado para que o NGINX suba; substitua via 'rbb-node prometheus clients'.
[[ -f "${PROM_HOME}/certs/client.pem" ]] || cp "${PROM_HOME}/certs/certificado.pem" "${PROM_HOME}/certs/client.pem"
chmod 644 "${PROM_HOME}/certs/"*

# Usuário da interface web (senha aleatória, gravada em ${PROM_HOME}/.htpasswd-initial, só leitura root).
if [[ ! -f "${PROM_HOME}/.htpasswd" ]]; then
  PW="$(openssl rand -base64 18)"
  htpasswd -cbB "${PROM_HOME}/.htpasswd" admin "${PW}"
  umask 077
  printf 'admin:%s\n' "${PW}" > "${PROM_HOME}/.htpasswd-initial"
  umask 022
fi

chown -R rbb:rbb "${PROM_HOME}"
chmod 600 "${PROM_HOME}/.htpasswd-initial" 2>/dev/null || true

cd "${PROM_HOME}"
sudo -u rbb -H docker compose up -d
echo "[rbb] Prometheus + NGINX iniciados em ${PROM_HOME}"
