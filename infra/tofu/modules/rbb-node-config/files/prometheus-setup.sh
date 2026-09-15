#!/usr/bin/env bash
# Bootstrap do nó prometheus<NN> da RBB. Chamado por rbb-node-setup.
# Cria a estrutura em ${DATA_MOUNT}/prometheus e sobe Prometheus + NGINX (443 UI, 8443 mTLS /federate).
set -euo pipefail

# shellcheck disable=SC1091
source /etc/rbb/node.env

PROM_HOME="${DATA_MOUNT}/prometheus"
mkdir -p "${PROM_HOME}"/{targets,certs,logs}
for f in prometheus.yml rules.yml nginx.conf docker-compose.yml; do
  cp -f "/etc/rbb/prometheus/${f}" "${PROM_HOME}/${f}"
done
# Alvos: sempre reescreve os locais; os federados só na primeira vez (depois via 'rbb-node prometheus federation')
cp -f /etc/rbb/prometheus/targets/local.json "${PROM_HOME}/targets/local.json"
[[ -f "${PROM_HOME}/targets/federation.json" ]] || cp /etc/rbb/prometheus/targets/federation.json "${PROM_HOME}/targets/federation.json"

# Certificado autoassinado do servidor (roteiro_prometheus_nginx.md, passo 2). Válido por 2 anos.
if [[ ! -f "${PROM_HOME}/certs/chave-privada.key" ]]; then
  CN="${PUBLIC_IP:-${PRIVATE_IP}}"
  openssl genrsa -out "${PROM_HOME}/certs/chave-privada.key" 4096
  openssl req -new -key "${PROM_HOME}/certs/chave-privada.key" \
    -out "${PROM_HOME}/certs/pedido.csr" \
    -subj "/C=BR/O=${ORGANIZATION_NAME}-RBB/CN=${CN}"
  openssl x509 -req -days 730 -in "${PROM_HOME}/certs/pedido.csr" \
    -signkey "${PROM_HOME}/certs/chave-privada.key" \
    -out "${PROM_HOME}/certs/certificado.pem"
fi
# client.pem: certificados dos demais partícipes (participantes/<rede>/certificados).
# Começa com o próprio certificado para que o NGINX suba; substitua via 'rbb-node prometheus clients'.
[[ -f "${PROM_HOME}/certs/client.pem" ]] || cp "${PROM_HOME}/certs/certificado.pem" "${PROM_HOME}/certs/client.pem"
chmod 644 "${PROM_HOME}/certs/"*

# Usuário da interface web (senha aleatória gravada em ${PROM_HOME}/.htpasswd-initial, legível só por root).
if [[ ! -f "${PROM_HOME}/.htpasswd" ]]; then
  PW="$(openssl rand -base64 18)"
  htpasswd -cbB "${PROM_HOME}/.htpasswd" admin "${PW}"
  (umask 077; printf 'admin:%s\n' "${PW}" > "${PROM_HOME}/.htpasswd-initial")
fi

chown -R rbb:rbb "${PROM_HOME}"
chown root:root "${PROM_HOME}/.htpasswd-initial" 2>/dev/null || true

cd "${PROM_HOME}"
sudo -u rbb -H docker compose up -d
echo "[rbb] Prometheus + NGINX iniciados em ${PROM_HOME}"
