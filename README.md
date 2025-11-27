# Documentação: Script de Instalação do Zabbix Proxy (SQLite3)

![Zabbix](https://img.shields.io/badge/Zabbix-7.0%20LTS-red?style=for-the-badge&logo=zabbix)
![OS](https://img.shields.io/badge/Debian-13%20(Trixie)-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Bash](https://img.shields.io/badge/Shell_Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)


Este documento detalha o funcionamento, pré-requisitos e uso do script `install_zabbix_proxy_sqlite3.sh`, projetado para automatizar a instalação e configuração de um Zabbix Proxy com banco de dados SQLite3 no Debian 13 (Trixie).

## 📋 Visão Geral

O script realiza a instalação completa do Zabbix Proxy, desde a configuração dos repositórios até o ajuste fino dos arquivos de configuração e inicialização do serviço. Ele é ideal para ambientes onde se deseja um deploy rápido e padronizado de proxies.

### O que o script faz?

1.  **Verificação de Ambiente**: Garante que o script está rodando como `root`.
2.  **Instalação de Dependências**: Instala pacotes essenciais como `wget`, `gnupg` e `lsb-release`.
3.  **Configuração de Repositório**: Adiciona o repositório oficial do Zabbix 7.0 LTS.
4.  **Instalação do Proxy**: Instala os pacotes `zabbix-proxy-sqlite3` e scripts SQL.
5.  **Configuração**:
    *   Define o IP do Zabbix Server.
    *   Configura o caminho do banco de dados SQLite3.
    *   (Opcional) Ajusta Hostname e Modo do Proxy.
6.  **Inicialização**: Cria diretórios necessários, ajusta permissões e inicia o serviço via `systemd`.

## 🚀 Como Usar

### Pré-requisitos
*   Sistema Operacional: Debian 13 (Trixie) ou compatível.
*   Acesso à Internet (para baixar pacotes).
*   Privilégios de superusuário (root).

### Execução

1.  Baixe ou crie o arquivo `install_zabbix_proxy_sqlite3.sh` no servidor.
2.  Dê permissão de execução:
    ```bash
    chmod +x install_zabbix_proxy_sqlite3.sh
    ```
3.  Execute o script:
    ```bash
    ./install_zabbix_proxy_sqlite3.sh
    ```

## ⚙️ Configurações e Variáveis

As principais variáveis estão definidas no início do script e podem ser alteradas conforme a necessidade do ambiente:

| Variável | Valor Padrão | Descrição |
| :--- | :--- | :--- |
| `ZABBIX_VERSION` | `"7.0"` | Versão do Zabbix a ser instalada. |
| `ZABBIX_SERVER_IP` | `"10.10.10.50"` | **Importante**: IP ou DNS do Zabbix Server que gerenciará este proxy. |
| `DB_PATH` | `/var/lib/zabbix/zabbix_proxy.db` | Caminho completo onde o arquivo do banco SQLite será criado. |

### Personalizações Comuns

*   **Alterar o IP do Server**: Edite a linha `ZABBIX_SERVER_IP="10.10.10.50"` com o IP correto do seu servidor Zabbix.
*   **Modo do Proxy**: O script mantém o padrão do pacote (geralmente Ativo). Para mudar para Passivo, descomente a linha `# sed -i 's/^ProxyMode=.*/ProxyMode=1/' ...` (ajuste para 1 se necessário).
*   **Hostname**: O script usa o hostname da máquina por padrão. Para forçar um nome específico, descomente e ajuste a linha do `Hostname=`.

## 🛠️ Estrutura do Script

### Detecção de SO
O script tenta detectar o codinome do sistema operacional (ex: `trixie`) automaticamente usando `/etc/os-release` ou `lsb_release`. Isso garante que o repositório correto seja baixado.

### Banco de Dados (SQLite3)
Diferente de instalações com MySQL/PostgreSQL, o SQLite3 não requer um serviço de banco de dados separado rodando. O banco é um arquivo local. O script garante que o diretório desse arquivo exista e pertença ao usuário `zabbix`.

## ✅ Verificação Pós-Instalação

Ao final da execução, o script exibe um resumo com:
*   Status do serviço (`active (running)`).
*   Versão instalada.
*   Caminho do banco de dados.
*   IP do Server configurado.

Para verificar os logs em caso de erro:
```bash
tail -f /var/log/zabbix/zabbix_proxy.log
```

---
**Autor**: Pliffisson Gomes
**Data**: Novembro/2025
