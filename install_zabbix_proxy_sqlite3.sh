#!/bin/bash
#
# Script de Instalação e Configuração do Zabbix Proxy (SQLite3) - Zabbix 7 LTS
# SO Alvo: Debian 13 (Trixie)
#
# Este script realiza:
# 1. Instalação de dependências e repositório oficial Zabbix.
# 2. Instalação do pacote zabbix-proxy-sqlite3.
# 3. Configuração do banco de dados SQLite3 (auto-criação).
# 4. Ajustes no arquivo de configuração (Server, DBName).
# 5. Habilitação e inicialização do serviço.
#

set -e

# --- Variáveis de Configuração ---
ZABBIX_VERSION="7.0"
# Detect OS Codename without relying on lsb_release (which might not be installed yet)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_CODENAME=${VERSION_CODENAME}
else
    # Fallback if os-release is missing (unlikely on Debian 13)
    OS_CODENAME=$(lsb_release -sc)
fi
# IP do Zabbix Server para onde o proxy aponta (Argumento 1 ou Padrão)
ZABBIX_SERVER_IP=${1:-"10.10.10.50"}
DB_PATH="/var/lib/zabbix/zabbix_proxy.db"

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

# Nota: O nome do pacote de release pode variar ligeiramente dependendo da build exata,
# mas o padrão segue zabbix-release_VERSION-REVISION+debianVERSION_all.deb.
# Vamos tentar baixar o mais recente para Debian 13.
REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/debian/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-2+debian13_all.deb"
TEMP_DEB="/tmp/zabbix-release.deb"

wget -O "$TEMP_DEB" "$REPO_URL" || {
    log_error "Falha ao baixar o pacote do repositório. Verifique a URL ou a conexão."
    exit 1
}

dpkg -i "$TEMP_DEB"
apt-get update

# --- 3. Instalação do Zabbix Proxy SQLite3 ---
log_info "Instalando zabbix-proxy-sqlite3..."
apt-get install -y zabbix-proxy-sqlite3 zabbix-sql-scripts

# --- 4. Configuração do Zabbix Proxy ---
log_info "Configurando /etc/zabbix/zabbix_proxy.conf..."

CONF_FILE="/etc/zabbix/zabbix_proxy.conf"

# Backup do arquivo original
# Backup do arquivo original (apenas se não existir backup prévio)
if [ ! -f "${CONF_FILE}.bak" ]; then
    cp "$CONF_FILE" "${CONF_FILE}.bak"
    log_info "Backup criado em ${CONF_FILE}.bak"
else
    log_info "Backup já existente. Mantendo original."
fi

# Ajustes de configuração
# Definindo modo passivo por padrão (ProxyMode=0 é ativo, 1 é passivo). 
# O padrão do pacote geralmente é ativo (0). Se precisar mudar, descomente abaixo.
# sed -i 's/^ProxyMode=.*/ProxyMode=0/' "$CONF_FILE"

# Configurando o Server (IP do Zabbix Server)
sed -i "s/^Server=.*/Server=${ZABBIX_SERVER_IP}/" "$CONF_FILE"

# Configurando o Hostname (Opcional: usa o hostname da máquina se não definido, 
# mas é boa prática definir explicitamente se souber o nome do proxy no frontend)
# sed -i "s/^Hostname=.*/Hostname=ZabbixProxy-$(hostname)/" "$CONF_FILE"

# Configurando o Banco de Dados SQLite3
# O pacote zabbix-proxy-sqlite3 já deve vir com DBName configurado, mas garantimos o caminho.
if grep -q "^DBName=" "$CONF_FILE"; then
    sed -i "s|^DBName=.*|DBName=${DB_PATH}|" "$CONF_FILE"
else
    echo "DBName=${DB_PATH}" >> "$CONF_FILE"
fi

# --- 5. Inicialização do Serviço ---
log_info "Habilitando e iniciando o serviço zabbix-proxy..."

# O diretório do banco deve pertencer ao usuário zabbix
mkdir -p $(dirname "$DB_PATH")
chown -R zabbix:zabbix $(dirname "$DB_PATH")

systemctl enable zabbix-proxy
systemctl restart zabbix-proxy

# --- 6. Validação ---
if systemctl is-active --quiet zabbix-proxy; then
    log_info "Zabbix Proxy instalado e rodando com sucesso!"
    echo "---------------------------------------------------"
    echo "Versão: $(zabbix_proxy -V | head -n 1)"
    echo "Banco de Dados: $DB_PATH"
    echo "Server Apontado: $ZABBIX_SERVER_IP"
    echo "Arquivo de Log: /var/log/zabbix/zabbix_proxy.log"
    echo "---------------------------------------------------"
else
    log_error "O serviço zabbix-proxy falhou ao iniciar. Verifique os logs:"
    echo "tail -n 20 /var/log/zabbix/zabbix_proxy.log"
    exit 1
fi

# --- 7. Limpeza ---
rm -f "$TEMP_DEB"
