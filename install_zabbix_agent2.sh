#!/bin/bash
#
# Script de Instalação e Configuração do Zabbix Agent 2 - Zabbix 7 LTS
# SO Alvo: Debian 13 (Trixie)
#
# Este script realiza:
# 1. Instalação de dependências e repositório oficial Zabbix.
# 2. Instalação do pacote zabbix-agent2 e seus plugins.
# 3. Configuração do arquivo zabbix_agent2.conf.
# 4. Habilitação e inicialização do serviço.
#

set -e

# --- Variáveis de Configuração ---
ZABBIX_VERSION="7.0"
ZABBIX_VERSION="7.0"
# Detect OS Codename safely
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_CODENAME=${VERSION_CODENAME}
else
    # Fallback if os-release is missing
    OS_CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

# IP do Zabbix Server ou Proxy (Argumento 1 ou Padrão)
ZABBIX_SERVER_IP=${1:-"10.10.10.50"}
HOSTNAME_ITEM="system.hostname" # Item padrão para hostname, ou defina um estático

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# --- Verificação de Privilégios ---
if [[ $EUID -ne 0 ]]; then
   log_error "Este script deve ser executado como root."
   exit 1
fi

# --- 1. Instalação de Dependências ---
log_info "Atualizando lista de pacotes e instalando dependências..."
apt-get update
apt-get install -y wget gnupg lsb-release

# --- 2. Adição do Repositório Zabbix 7 LTS ---
log_info "Configurando repositório Zabbix ${ZABBIX_VERSION} LTS para Debian ${OS_CODENAME}..."

REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/debian/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-2+debian13_all.deb"
TEMP_DEB="/tmp/zabbix-release.deb"

wget -O "$TEMP_DEB" "$REPO_URL" || {
    log_error "Falha ao baixar o pacote do repositório. Verifique a URL ou a conexão."
    exit 1
}

dpkg -i "$TEMP_DEB"
apt-get update

# --- 3. Instalação do Zabbix Agent 2 ---
log_info "Instalando zabbix-agent2 e plugins..."
# O pacote zabbix-agent2 já inclui os plugins principais, mas instalamos o pacote de plugins
# separadamente se houver necessidade específica, ou apenas o agente.
apt-get install -y zabbix-agent2 zabbix-agent2-plugin-*

# --- 4. Configuração do Zabbix Agent 2 ---
log_info "Configurando /etc/zabbix/zabbix_agent2.conf..."

CONF_FILE="/etc/zabbix/zabbix_agent2.conf"

# Backup do arquivo original
# Backup do arquivo original (apenas se não existir backup prévio)
if [ ! -f "${CONF_FILE}.bak" ]; then
    cp "$CONF_FILE" "${CONF_FILE}.bak"
    log_info "Backup criado em ${CONF_FILE}.bak"
else
    log_info "Backup já existente. Mantendo original."
fi

# Configurando Server (Checagens passivas)
sed -i "s/^Server=.*/Server=${ZABBIX_SERVER_IP}/" "$CONF_FILE"

# Configurando ServerActive (Checagens ativas / Auto-registro)
sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_SERVER_IP}/" "$CONF_FILE"

# Configurando Hostname
# Se quiser usar o hostname da máquina:
sed -i "s/^Hostname=.*/Hostname=$(hostname)/" "$CONF_FILE"
# Se preferir HostnameItem (comentado por padrão no conf original, mas útil):
# sed -i "s/^# HostnameItem=.*/HostnameItem=system.hostname/" "$CONF_FILE"

# --- 5. Inicialização do Serviço ---
log_info "Habilitando e iniciando o serviço zabbix-agent2..."

systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# --- 6. Validação ---
if systemctl is-active --quiet zabbix-agent2; then
    log_info "Zabbix Agent 2 instalado e rodando com sucesso!"
    echo "---------------------------------------------------"
    echo "Versão: $(zabbix_agent2 -V | head -n 1)"
    echo "Server Apontado: $ZABBIX_SERVER_IP"
    echo "Arquivo de Log: /var/log/zabbix/zabbix_agent2.log"
    echo "---------------------------------------------------"
else
    log_error "O serviço zabbix-agent2 falhou ao iniciar. Verifique os logs:"
    echo "tail -n 20 /var/log/zabbix/zabbix_agent2.log"
    exit 1
fi

# --- 7. Limpeza ---
rm -f "$TEMP_DEB"
