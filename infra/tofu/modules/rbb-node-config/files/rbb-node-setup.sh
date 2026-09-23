#!/usr/bin/env bash
# Bootstrap de um nó RBB (executado uma vez pelo cloud-init, como root).
# Implementa, de forma automatizada, os passos 1 a 4 do roteiro_adicao_nos.md:
#   - prepara volume de dados, Docker e usuário de serviço
#   - baixa o start-network (rbb-cli) na versão fixada
#   - cria o nó (chaves), configura portas/endereço/variáveis via rbb-cli
#   - copia o genesis.json, prepara static-nodes.json e permissionamento local (observer-boot)
#   - renderiza os templates e inicia o Besu (versão fixada) com docker compose
# É idempotente: pode ser reexecutado com segurança (rbb-node-setup).
set -euo pipefail

log() { printf '[rbb-setup %s] %s\n' "$(date -Is)" "$*"; }

# shellcheck disable=SC1091
source /etc/rbb/node.env
export DEBIAN_FRONTEND=noninteractive

RBB_USER=rbb
RBB_UID=1100
SN_DIR="${DATA_MOUNT}/start-network"

# ---------------------------------------------------------------------------
# 1. Volume de dados
# ---------------------------------------------------------------------------
find_data_device() {
  # Disco extra: tipo disk, sem partições, sem filesystem, diferente do disco raiz;
  # ou disco já rotulado rbbdata (reprovisionamento da VM mantendo o volume).
  local root_disk d
  root_disk="$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null || true)"
  if blkid -L rbbdata >/dev/null 2>&1; then blkid -L rbbdata; return; fi
  for d in $(lsblk -dnpo NAME,TYPE | awk '$2=="disk"{print $1}'); do
    [[ "$(basename "$d")" == "${root_disk}" ]] && continue
    [[ -n "$(lsblk -no NAME "$d" | tail -n +2)" ]] && continue
    [[ -n "$(blkid -p -o value -s TYPE "$d" 2>/dev/null)" ]] && continue
    echo "$d"; return
  done
}

mount_data_volume() {
  mkdir -p "${DATA_MOUNT}"
  if mountpoint -q "${DATA_MOUNT}"; then
    log "volume já montado em ${DATA_MOUNT}"
    return
  fi
  if [[ "${DATA_VOLUME}" != "true" ]]; then
    log "DATA_VOLUME=false: usando disco raiz em ${DATA_MOUNT}"
    return
  fi

  # O volume é anexado pela infra depois de a VM existir; espera até 20 minutos.
  local dev=""
  for _ in $(seq 1 240); do
    dev="$(find_data_device)"
    [[ -n "${dev}" ]] && break
    sleep 5
  done
  if [[ -z "${dev}" ]]; then
    log "AVISO: nenhum volume de dados encontrado; usando disco raiz em ${DATA_MOUNT}. Reexecute rbb-node-setup após anexar o volume."
    return
  fi
  if [[ "$(blkid -p -o value -s TYPE "${dev}" 2>/dev/null || true)" == "" ]]; then
    log "formatando ${dev} (ext4, rótulo rbbdata)"
    mkfs.ext4 -q -L rbbdata "${dev}"
  fi
  grep -q 'LABEL=rbbdata' /etc/fstab || printf 'LABEL=rbbdata %s ext4 defaults,nofail 0 2\n' "${DATA_MOUNT}" >> /etc/fstab

  if [[ -n "$(ls -A "${DATA_MOUNT}" 2>/dev/null)" ]]; then
    # Volume chegou depois de o bootstrap ter usado o disco raiz: migra os dados.
    log "migrando ${DATA_MOUNT} do disco raiz para ${dev}"
    if [[ -f "${SN_DIR}/docker-compose.yml" ]]; then
      (cd "${SN_DIR}" && docker compose down >/dev/null 2>&1 || true)
    fi
    if [[ -f "${DATA_MOUNT}/prometheus/docker-compose.yml" ]]; then
      (cd "${DATA_MOUNT}/prometheus" && docker compose down >/dev/null 2>&1 || true)
    fi
    mkdir -p /mnt/rbbdata && mount "${dev}" /mnt/rbbdata
    cp -a "${DATA_MOUNT}/." /mnt/rbbdata/
    umount /mnt/rbbdata
    mv "${DATA_MOUNT}" "${DATA_MOUNT}.root-disk.bak"
    mkdir -p "${DATA_MOUNT}"
  fi
  mount "${DATA_MOUNT}"
  log "volume ${dev} montado em ${DATA_MOUNT}"
}

# ---------------------------------------------------------------------------
# 2. Docker (repositório oficial) + shim docker-compose (o rbb-cli/roteiro usam docker-compose)
# ---------------------------------------------------------------------------
install_docker() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "docker já instalado"
  else
    log "instalando docker"
    install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
      chmod a+r /etc/apt/keyrings/docker.asc
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update -q
    apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  systemctl enable --now docker
  if [[ ! -x /usr/local/bin/docker-compose ]]; then
    printf '#!/usr/bin/env bash\nexec docker compose "$@"\n' > /usr/local/bin/docker-compose
    chmod 0755 /usr/local/bin/docker-compose
  fi
}

# ---------------------------------------------------------------------------
# 3. Usuário de serviço
# ---------------------------------------------------------------------------
create_user() {
  if ! id "${RBB_USER}" >/dev/null 2>&1; then
    useradd --uid "${RBB_UID}" --create-home --shell /bin/bash "${RBB_USER}"
  fi
  usermod -aG docker "${RBB_USER}"
  chown "${RBB_USER}:${RBB_USER}" "${DATA_MOUNT}"
  cat > /etc/profile.d/rbb.sh <<PROFILE
# Ambiente RBB (gerado pelo bootstrap)
export RBB_HOME="${DATA_MOUNT}"
export IMAGE_BESU="${BESU_IMAGE}"
export RBB_IMAGE="${RBB_CLI_IMAGE}"
PROFILE
}

as_rbb() { sudo -u "${RBB_USER}" -H env IMAGE_BESU="${BESU_IMAGE}" RBB_IMAGE="${RBB_CLI_IMAGE}" bash -c "cd '${SN_DIR}' && $*"; }

# ---------------------------------------------------------------------------
# 4. start-network (rbb-cli) na versão fixada — passo 1.2 do roteiro
# ---------------------------------------------------------------------------
install_start_network() {
  if [[ -x "${SN_DIR}/rbb-cli" ]]; then
    log "start-network já presente em ${SN_DIR}"
  else
    local ver="${START_NETWORK_VERSION#v}"
    log "baixando start-network ${START_NETWORK_VERSION}"
    curl -#SL "https://github.com/RBBNet/start-network/archive/refs/tags/${START_NETWORK_VERSION}.tar.gz" | tar xz -C "${DATA_MOUNT}"
    mv "${DATA_MOUNT}/start-network-${ver}" "${SN_DIR}"
  fi
  # Template de compose específico da rede (ex.: participantes/piloto/docker-compose.yml.hbs)
  if [[ -f /etc/rbb/docker-compose.yml.hbs ]]; then
    cp -f /etc/rbb/docker-compose.yml.hbs "${SN_DIR}/docker-compose.yml.hbs"
  fi
  # .env é lido pelo docker compose (IMAGE_BESU fixado — CAUTION do roteiro, passo 4)
  cat > "${SN_DIR}/.env" <<ENV
IMAGE_BESU=${BESU_IMAGE}
CPUS_LIMIT_BESU_CONTAINER=${CONTAINER_CPUS}
MEMORY_LIMIT_BESU_CONTAINER=${CONTAINER_MEMORY}
ENV
  chown -R "${RBB_USER}:${RBB_USER}" "${SN_DIR}"
  # Pré-carrega imagens (rbb-cli e Besu)
  docker pull -q "${RBB_CLI_IMAGE}" || true
  docker pull -q "${BESU_IMAGE}" || true
}

# ---------------------------------------------------------------------------
# 5. Criação e configuração do nó — passo 2.5 do roteiro
# ---------------------------------------------------------------------------
node_ref() {
  # Nomes com hífen precisam de nodes["nome"] (guia_rbb-cli.md)
  if [[ "${NODE_NAME}" == *-* ]]; then printf 'nodes["%s"]' "${NODE_NAME}"; else printf 'nodes.%s' "${NODE_NAME}"; fi
}

configure_node() {
  local ref; ref="$(node_ref)"
  local infra="${SN_DIR}/infra.json"

  if [[ ! -f "${SN_DIR}/.env.configs/nodes/${NODE_NAME}/key" ]]; then
    log "criando nó ${NODE_NAME} (chaves)"
    as_rbb "./rbb-cli node create ${NODE_NAME}"
  fi

  if [[ -f "${infra}" ]] && jq -e --arg n "${NODE_NAME}" '.nodes[$n].address? // empty' "${infra}" >/dev/null 2>&1; then
    log "nó ${NODE_NAME} já configurado no infra.json (mantendo)"
  else
    log "configurando ${NODE_NAME} via rbb-cli"
    as_rbb "./rbb-cli config set '${ref}.ports=[\"${RPC_PORT}:8545\",\"${METRICS_PORT}:9545\"]'"
    as_rbb "./rbb-cli config set '${ref}.address=\"${P2P_ADDRESS}\"'"
    if [[ "${NODE_TYPE}" == "validator" || "${NODE_TYPE}" == "writer" || "${NODE_TYPE}" == "observer" ]]; then
      as_rbb "./rbb-cli config set '${ref}.environment.BESU_DISCOVERY_ENABLED=false'"
    fi
    if [[ "${NODE_TYPE}" == "observer" ]]; then
      # instanciar_observer.md: observer interno (satélite) sem permissionamento on chain de nós;
      # conecta-se apenas aos observer-boots da própria organização (static-nodes, IP interno).
      as_rbb "./rbb-cli config set '${ref}.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false'"
      sed -i '/BESU_PERMISSIONS_NODES_CONTRACT_ENABLED/d' "${SN_DIR}/docker-compose.yml.hbs"
    fi
    if [[ "${NODE_TYPE}" == "observer-boot" ]]; then
      # Passo 2.5.4: sem permissionamento on chain; permissionamento local de contas com lista vazia
      as_rbb "./rbb-cli config set '${ref}.environment.BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED=false'"
      as_rbb "./rbb-cli config set '${ref}.environment.BESU_PERMISSIONS_NODES_CONTRACT_ENABLED=false'"
      as_rbb "./rbb-cli config set '${ref}.environment.BESU_PERMISSIONS_ACCOUNTS_CONFIG_FILE_ENABLED=true'"
      as_rbb "./rbb-cli config set '${ref}.environment.BESU_PERMISSIONS_ACCOUNTS_CONFIG_FILE=\"/var/lib/besu/permissioned-accounts.toml\"'"
      # Evita chaves duplicadas no compose (instanciar_observer-boot.md, passo 5)
      sed -i '/BESU_PERMISSIONS_ACCOUNTS_CONTRACT_ENABLED/d;/BESU_PERMISSIONS_NODES_CONTRACT_ENABLED/d' "${SN_DIR}/docker-compose.yml.hbs"
    fi
    if [[ -n "${EXTRA_ENV}" ]]; then
      for kv in ${EXTRA_ENV}; do
        as_rbb "./rbb-cli config set '${ref}.environment.${kv%%=*}=\"${kv#*=}\"'"
      done
    fi
  fi

  local vol="${SN_DIR}/volumes/${NODE_NAME}"
  mkdir -p "${vol}"
  if [[ "${NODE_TYPE}" == "observer-boot" && ! -f "${vol}/permissioned-accounts.toml" ]]; then
    printf 'accounts-allowlist=[]\n' > "${vol}/permissioned-accounts.toml"
  fi
  # static-nodes.json vazio: os peers são definidos depois com 'rbb-node peers set' (passo 3 do roteiro)
  if [[ "${NODE_TYPE}" != "boot" && ! -f "${vol}/static-nodes.json" ]]; then
    printf '[]\n' > "${vol}/static-nodes.json"
  fi

  # Genesis (passo 3): fornecido pela infra ou copiado depois manualmente
  if [[ -f /etc/rbb/genesis.json && ! -f "${SN_DIR}/.env.configs/genesis.json" ]]; then
    cp /etc/rbb/genesis.json "${SN_DIR}/.env.configs/genesis.json"
  fi
  chown -R "${RBB_USER}:${RBB_USER}" "${SN_DIR}"

  as_rbb "./rbb-cli config render-templates" >/dev/null
}

# ---------------------------------------------------------------------------
# 6. Início do nó — passo 4 do roteiro
# ---------------------------------------------------------------------------
start_node() {
  if [[ ! -f "${SN_DIR}/.env.configs/genesis.json" ]]; then
    log "genesis.json ausente: Besu NÃO iniciado. Copie o genesis para ${SN_DIR}/.env.configs/ e execute 'rbb-node up'."
    return
  fi
  log "iniciando Besu (${BESU_IMAGE})"
  as_rbb "docker compose up -d"
}

write_node_info() {
  rbb-node info > "${DATA_MOUNT}/node-info.json" 2>/dev/null || true
  chown "${RBB_USER}:${RBB_USER}" "${DATA_MOUNT}/node-info.json" 2>/dev/null || true
}

main() {
  log "bootstrap ${NODE_NAME} (${NODE_TYPE}) org=${ORGANIZATION} rede=${RBB_NETWORK}"
  install_docker
  mount_data_volume
  create_user
  install_start_network
  if [[ "${NODE_TYPE}" == "prometheus" ]]; then
    /usr/local/sbin/rbb-prometheus-setup
  else
    configure_node
    start_node
    write_node_info
  fi
  log "bootstrap concluído"
}

main "$@"
