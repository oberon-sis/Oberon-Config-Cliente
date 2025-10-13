#!/bin/bash
# ==============================================================================
TARGET_DIR="cliente"

PYTHON_DIR="Oberon-Coleta-Python"
JAVA_DIR="Oberon-Coleta-Java"


# Função para imprimir uma linha separadora com bordas duplas
print_separator() {
    echo "══════════════════════════════════════════════════════════════════════════════════"
}

# Função para imprimir um cabeçalho
print_header() {
    print_separator
    echo "║ $1 ║"
    print_separator
}

# Cria e navega para o diretório alvo
create_target_directory() {
    print_header "CONFIGURAÇÃO DO DIRETÓRIO"
    echo "Criando e navegando para o diretório alvo (~/$TARGET_DIR)..."
    if [ ! -d "$HOME/$TARGET_DIR" ]; then
        mkdir -p "$HOME/$TARGET_DIR"
        echo "Diretório $HOME/$TARGET_DIR criado."
    else
        echo "Diretório $HOME/$TARGET_DIR já existe."
    fi
    cd "$HOME/$TARGET_DIR" || { echo "Erro ao entrar no diretório $HOME/$TARGET_DIR. Abortando."; exit 1; }
    echo "Localização atual: $(pwd)"
    print_separator
}

# Instala Python e o gerenciador de ambiente virtual (venv)
install_python() {
    print_header "INSTALAÇÃO DO PYTHON E VENV"
    echo "Verificando e instalando Python3 e python3-venv..."
    # Verifica se o python3 está instalado
    if ! command -v python3 &> /dev/null; then
        sudo apt install python3 -y
    fi
    # Instala o pacote venv para a Ubuntu
    sudo apt install python3-venv -y
    echo "Python3 e python3-venv instalados ou já existentes."
    print_separator
}

# Instala Java OpenJDK 17 
install_java() {
    print_header "INSTALAÇÃO DO JAVA"
    echo "Verificando e instalando OpenJDK 17..."
    if ! command -v java &> /dev/null || ! java -version 2>&1 | grep "version \"17" &> /dev/null; then
        sudo apt install openjdk-17-jdk -y
        echo "OpenJDK 17 instalado."
    else
        echo "OpenJDK 17 já está instalado."
    fi
    print_separator
}

# Clona o repositório do projeto Python
clone_repository_python() {
    print_header "CLONAGEM DO REPOSITÓRIO PYTHON"
    PYTHON_REPO_URL="https://github.com/oberon-sis/Oberon-Coleta-Python.git" 

    echo "Clonando repositório Python de $PYTHON_REPO_URL em $TARGET_DIR/$PYTHON_DIR..."
    if [ ! -d "$PYTHON_DIR" ]; then
        git clone "$PYTHON_REPO_URL" "$PYTHON_DIR"
        if [ $? -eq 0 ]; then
            echo "Repositório Python clonado com sucesso."
        else
            echo "ERRO: Falha ao clonar o repositório Python. Verifique a URL."
        fi
    else
        echo "Diretório $PYTHON_DIR já existe. Pulando a clonagem."
    fi
    print_separator
}

# Cria o venv e instala as dependências
setup_python_environment() {
    print_header "SETUP DO AMBIENTE PYTHON (VENV E DEPENDÊNCIAS)"

    if [ -d "$PYTHON_DIR" ]; then
        cd "$PYTHON_DIR"
        
        echo "Criando ambiente virtual (venv)..."
        python3 -m venv venv
        
        if [ -d "venv" ]; then
            echo "Ambiente virtual criado em $PYTHON_DIR/venv."
            
            echo "Instalando dependências de requirements.txt..."
            if [ -f "requirements.txt" ]; then
                ./venv/bin/pip install -r requirements.txt
                
                if [ $? -eq 0 ]; then
                    echo "Dependências Python instaladas com sucesso."
                else
                    echo "ERRO: Falha ao instalar as dependências. Verifique o requirements.txt."
                fi
            else
                echo "AVISO: requirements.txt não encontrado em $PYTHON_DIR. Pulando instalação de dependências."
            fi
            
        else
            echo "ERRO: Falha ao criar o ambiente virtual (venv)."
        fi
        
        cd ..
    else
        echo "AVISO: Diretório do projeto Python ($PYTHON_DIR) não encontrado. Pulando o setup do ambiente."
    fi
    print_separator
}


# Cria e configura arquivos de ambiente .env
configure_env_files() {
    print_header "CONFIGURAÇÃO DE ARQUIVOS DE AMBIENTE (.ENV)"
    
    echo "Criando arquivo .env para o projeto Python em $TARGET_DIR/$PYTHON_DIR..."
    ENV_FILE="$PYTHON_DIR/.env"

    if [ ! -f "$ENV_FILE" ]; then
        cat << EOF > "$ENV_FILE"
USER_DB =ClienteOberon
PASSWORD_DB =ClienteOberon123
HOST_DB =221.72.209.164
DATABASE_DB =bdOberon
EOF
        echo "Arquivo $ENV_FILE criado com conteúdo padrão."
    else
        echo "Arquivo $ENV_FILE já existe. Pulando a criação."
    fi
    print_separator
}


clone_repository_java() {
    print_header "CLONAGEM DO REPOSITÓRIO JAVA"
    JAVA_REPO_URL="" 

    echo "Clonando repositório Java de $JAVA_REPO_URL em $TARGET_DIR/$JAVA_DIR..."
    if [ ! -d "$JAVA_DIR" ]; then
        git clone "$JAVA_REPO_URL" "$JAVA_DIR"
        if [ $? -eq 0 ]; then
            echo "Repositório Java clonado com sucesso."
        else
            echo "ERRO: Falha ao clonar o repositório Java. Verifique a URL."
        fi
    else
        echo "Diretório $JAVA_DIR já existe. Pulando a clonagem."
    fi
    print_separator
}

print_separator
echo "║           SCRIPT DE CONFIGURAÇÃO INICIAL DA OBERON                     ║"
print_separator
echo """
      ███████     ███████████  ██████████ ███████████      ███████     ██████   █████
    ███▒▒▒▒▒███ ▒▒███▒▒▒▒▒███▒▒███▒▒▒▒▒█▒▒███▒▒▒▒▒███   ███▒▒▒▒▒███ ▒▒██████ ▒▒███ 
  ███    ▒▒███ ▒███    ▒███ ▒███  █ ▒  ▒███    ▒███  ███    ▒▒███ ▒███▒███ ▒███ 
  ▒███    ▒███ ▒██████████  ▒██████    ▒██████████  ▒███    ▒███ ▒███▒▒███▒███ 
  ▒███    ▒███ ▒███▒▒▒▒▒███ ▒███▒▒█    ▒███▒▒▒▒▒███ ▒███    ▒███ ▒███ ▒▒██████ 
  ▒▒███    ███  ▒███    ▒███ ▒███ ▒  █ ▒███    ▒███ ▒▒███    ███  ▒███  ▒▒█████ 
  ▒▒▒███████▒  ███████████  ██████████ █████  █████ ▒▒▒███████▒  █████  ▒▒█████
      ▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒  ▒▒▒▒▒      ▒▒▒▒▒▒▒    ▒▒▒▒▒    ▒▒▒▒▒    
"""
print_separator
echo "║             CONFIGURAÇÃO DO AMBIENTE VIRTUAL DO CLIENTE                  ║"
print_separator

# Volta para o diretório home para começar
cd ~ 

print_header "ATUALIZAÇÃO DE PACOTES DO SISTEMA"
echo "Atualizando pacotes (apt update/upgrade)..."
sudo apt update -qq -y
sudo apt upgrade -qq -y
print_separator

# Execução das funções de configuração
create_target_directory 

install_python 
install_java

# Configuração do projeto Python
clone_repository_python
configure_env_files
setup_python_environment 

# Configuração do projeto Java
clone_repository_java


print_header "FINALIZAÇÃO DO SETUP"
echo "O script de configuração foi concluído. Verifique o output para erros."
echo "Os repositórios foram clonados em (~/$TARGET_DIR)."
echo "Para ativar o ambiente Python, use: cd ~/$TARGET_DIR/$PYTHON_DIR && source venv/bin/activate"
print_separator

# Fim do script