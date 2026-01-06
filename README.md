# Documentação: Scripts de Instalação Zabbix (Agent 2 & Proxy SQLite3)

![Zabbix](https://img.shields.io/badge/Zabbix-7.0%20LTS-red?style=for-the-badge&logo=zabbix)
![OS](https://img.shields.io/badge/Debian-13%20(Trixie)-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Bash](https://img.shields.io/badge/Shell_Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

Este repositório contém scripts automatizados para instalação e configuração do **Zabbix Agent 2** e **Zabbix Proxy (SQLite3)** no Debian 13 (Trixie).

## 📋 Visão Geral

Os scripts realizam a instalação completa, desde a configuração dos repositórios oficiais até o ajuste fino dos arquivos de configuração e inicialização dos serviços.

### Funcionalidades Principais
*   **Detecção Automática de SO**: Suporte robusto para detecção do codinome do Debian.
*   **Backup Seguro**: Preserva o arquivo de configuração original (`.bak`) mesmo se o script for rodado múltiplas vezes.
*   **Flexibilidade**: Aceita o IP do servidor como argumento na linha de comando.
*   **Limpeza**: Remove arquivos temporários automoticamente após a instalação.

## 🚀 Como Usar

### Pré-requisitos
*   Sistema Operacional: Debian 13 (Trixie) ou compatível via fallback.
*   Acesso à Internet.
*   Privilégios de superusuário (root).

### 1. Instalação do Zabbix Agent 2

`install_zabbix_agent2.sh`

```bash
chmod +x install_zabbix_agent2.sh
# Uso: ./script.sh [IP_DO_SERVER]
./install_zabbix_agent2.sh 192.168.1.50
```
Se nenhum argumento for passado, o IP padrão `10.10.10.50` será usado.

### 2. Instalação do Zabbix Proxy (SQLite3)

`install_zabbix_proxy_sqlite3.sh`

```bash
chmod +x install_zabbix_proxy_sqlite3.sh
# Uso: ./script.sh [IP_DO_SERVER]
./install_zabbix_proxy_sqlite3.sh 192.168.1.50
```
*   Configura o banco de dados SQLite3 automaticamente em `/var/lib/zabbix/zabbix_proxy.db`.
*   O diretório e permissões são ajustados automaticamente.

## ⚙️ Variáveis e Configurações

| Variável | Valor Padrão | Descrição |
| :--- | :--- | :--- |
| `ZABBIX_VERSION` | `"7.0"` | Versão do Zabbix LTS. |
| `ZABBIX_SERVER_IP` | `10.10.10.50` | IP do Zabbix Server. Pode ser sobrescrito pelo 1º argumento. |
| `DB_PATH` | `/var/lib/zabbix/...` | (Apenas Proxy) Caminho do banco SQLite3. |

## ✅ Verificação Pós-Instalação

Ao final, os scripts exibem um resumo com o status do serviço e versão instalada.

Para verificar os logs:
```bash
# Agent 2
tail -f /var/log/zabbix/zabbix_agent2.log

# Proxy
tail -f /var/log/zabbix/zabbix_proxy.log
```

---
**Autor**: Pliffisson Gomes
**Data atualizada**: Janeiro/2026
