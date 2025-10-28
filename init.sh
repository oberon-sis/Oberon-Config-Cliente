#!/bin/bash
TARGET_DIR="cliente"
PYTHON_DIR="Oberon-Coleta-Python"
JAVA_DIR="Oberon-Coleta-Java"

# Variáveis
PYTHON_REPO_URL="https://github.com/oberon-sis/Oberon-Coleta-Python.git" 
JAVA_REPO_URL="https://github.com/oberon-sis/Oberon-Coleta-Java.git"

print_separator() {
    echo "══════════════════════════════════════════════════════════════════════════════════"
}

print_header() {
    print_separator
    echo "║ $1 ║"
    print_separator
}

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

install_python() {
    print_header "INSTALAÇÃO DO PYTHON E VENV"
    echo "Verificando e instalando Python3 e python3-venv..."
    if ! command -v python3 &> /dev/null; then
        echo "Python3 não encontrado. Instalando..."
        sudo apt install python3 -y
    fi
    sudo apt install python3-venv -y
    echo "Python3 e python3-venv instalados ou já existentes."
    print_separator
}

install_java() {
    print_header "INSTALAÇÃO DO JAVA"
    echo "Verificando e instalando OpenJDK 17..."
    if ! command -v java &> /dev/null || ! java -version 2>&1 | grep "version \"17" &> /dev/null; then
        echo "OpenJDK 17 não encontrado. Instalando..."
        sudo apt install openjdk-17-jdk -y
        echo "OpenJDK 17 instalado."
    else
        echo "OpenJDK 17 já está instalado."
    fi
    print_separator
}

install_maven() {
    print_header "INSTALAÇÃO DO MAVEN"
    echo "Verificando e instalando Maven..."
    if ! command -v mvn &> /dev/null; then
        sudo apt install maven -y
        echo "Maven instalado."
    else
        echo "Maven já está instalado."
    fi 
    print_separator
}

clone_repository_python() {
    print_header "CLONAGEM DO REPOSITÓRIO PYTHON"
    echo "Clonando repositório Python de $PYTHON_REPO_URL em $(pwd)/$PYTHON_DIR..."
    if [ ! -d "$PYTHON_DIR" ]; then
        git clone "$PYTHON_REPO_URL" "$PYTHON_DIR"
        if [ $? -eq 0 ]; then
            echo "Repositório Python clonado com sucesso."
        else
            echo "ERRO: Falha ao clonar o repositório Python. Verifique a URL e a conectividade."
        fi
    else
        echo "Diretório $PYTHON_DIR já existe. Pulando a clonagem."
    fi
    print_separator
}

setup_python_environment() {
    print_header "SETUP DO AMBIENTE PYTHON (VENV E DEPENDÊNCIAS)"

    if [ -d "$PYTHON_DIR" ]; then
        cd "$PYTHON_DIR"
        
        echo "Criando ambiente virtual (venv)..."
        python3 -m venv venv
        
        if [ -d "venv" ]; then
            echo "Ambiente virtual criado em $(pwd)/venv."
            
            echo "Instalando dependências de requirements.txt..."
            if [ -f "requirements.txt" ]; then
                ./venv/bin/pip install -r requirements.txt
                
                if [ $? -eq 0 ]; then
                    echo "Dependências Python instaladas com sucesso."
                else
                    echo "ERRO: Falha ao instalar as dependências. Verifique o requirements.txt."
                fi
            else
                echo "AVISO: requirements.txt não encontrado em $(pwd). Pulando instalação de dependências."
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


configure_env_files() {
    print_header "CONFIGURAÇÃO DE ARQUIVOS DE AMBIENTE (.ENV)"
    
    ENV_FILE="$PYTHON_DIR/.env"

    echo "Criando arquivo .env para o projeto Python em $(pwd)/$ENV_FILE..."

    if [ ! -f "$ENV_FILE" ]; then
        cat << EOF > "$ENV_FILE"
USER_DB=oberon_cliente
PASSWORD_DB=ClienteOberon123
HOST_DB=44.207.133.113
DATABASE_DB=bdOberon
EOF
        echo "Arquivo $ENV_FILE criado com conteúdo padrão."
    else
        echo "Arquivo $ENV_FILE já existe. Pulando a criação."
    fi
    print_separator
}


clone_repository_java() {
    print_header "CLONAGEM DO REPOSITÓRIO JAVA"

    if [ -z "$JAVA_REPO_URL" ]; then
        echo "ERRO: A variável JAVA_REPO_URL está vazia. Não é possível clonar o projeto Java."
        print_separator
        return 1
    fi

    echo "Clonando repositório Java de $JAVA_REPO_URL em $(pwd)/$JAVA_DIR..."
    if [ ! -d "$JAVA_DIR" ]; then
        git clone "$JAVA_REPO_URL" "$JAVA_DIR"
        if [ $? -eq 0 ]; then
            echo "Repositório Java clonado com sucesso."
        else
            echo "ERRO: Falha ao clonar o repositório Java. Verifique a URL e a conectividade."
        fi
    else
        echo "Diretório $JAVA_DIR já existe. Pulando a clonagem."
    fi
    print_separator
}

configure_repository_java(){
    print_header "CONFIGURAÇÃO E COMPILAÇÃO DO PROJETO JAVA (MAVEN)"
    
    if [ -d "$JAVA_DIR" ]; then
        if [ -d "$JAVA_DIR/looca-api" ]; then
            cd "$JAVA_DIR/looca-api"
            echo "Executando 'mvn clean install' em $(pwd)..."
            
            mvn clean install 
            
            if [ $? -eq 0 ]; then
                echo "Build Maven concluído com sucesso."
            else
                echo "ERRO: Falha no 'mvn clean install'. Verifique a estrutura do projeto e o Maven."
            fi

            cd ../..
        else
            echo "ERRO: Subdiretório 'looca-api' não encontrado em $JAVA_DIR. Pulando a configuração Maven."
        fi
    else
        echo "AVISO: Diretório do projeto Java ($JAVA_DIR) não encontrado. Pulando a configuração."
    fi
    print_separator
}

runJavaEmSegundoPlano(){
    print_header "EXECUÇÃO DO PROJETO JAVA EM SEGUNDO PLANO"
    
    JAVA_JAR_PATH="$JAVA_DIR/looca-api/target/looca-api-1.0.0-jar-with-dependencies.jar"

    if [ -f "$JAVA_JAR_PATH" ]; then
        echo "Iniciando o JAR Java em segundo plano (PID: $!)..."
        java -jar "$JAVA_JAR_PATH" &
        echo "Comando de inicialização: java -jar $JAVA_JAR_PATH &"
    else
        echo "ERRO: Arquivo JAR ($JAVA_JAR_PATH) não encontrado. Verifique se a compilação Maven funcionou."
    fi
    print_separator
}

runPythonEmSegundoPlano(){
    print_header "EXECUÇÃO DO PROJETO PYTHON EM SEGUNDO PLANO"

    PYTHON_SCRIPT_PATH="$PYTHON_DIR/main.py"
    PYTHON_VENV_PYTHON="$PYTHON_DIR/venv/bin/python"

    if [ -f "$PYTHON_SCRIPT_PATH" ] && [ -f "$PYTHON_VENV_PYTHON" ]; then
        echo "Iniciando o script Python em segundo plano (PID: $!)..."
        "$PYTHON_VENV_PYTHON" "$PYTHON_SCRIPT_PATH" &
        echo "Comando de inicialização: $PYTHON_VENV_PYTHON $PYTHON_SCRIPT_PATH &"
    else
        echo "ERRO: Script Python ($PYTHON_SCRIPT_PATH) ou VENV não encontrado. Pulando a execução."
    fi
    print_separator
}
print_separator
echo "║           SCRIPT DE CONFIGURAÇÃO INICIAL DA OBERON                     ║"
print_separator
echo """
      ███████     ███████████   ██████████ ███████████       ███████     ██████   █████
    ███▒▒▒▒▒███ ▒▒███▒▒▒▒▒███▒▒███▒▒▒▒▒█▒▒███▒▒▒▒▒███   ███▒▒▒▒▒███ ▒▒██████ ▒▒███ 
  ███    ▒▒███ ▒███    ▒███ ▒███  █ ▒  ▒███    ▒███  ███    ▒▒███ ▒███▒███ ▒███ 
  ▒███    ▒███ ▒██████████  ▒██████     ▒██████████  ▒███    ▒███ ▒███▒▒███▒███ 
  ▒███    ▒███ ▒███▒▒▒▒▒███ ▒███▒▒█     ▒███▒▒▒▒▒███ ▒███    ▒███ ▒███ ▒▒██████ 
  ▒▒███    ███  ▒███    ▒███ ▒███ ▒  █ ▒███    ▒███ ▒▒███    ███  ▒███  ▒▒█████ 
  ▒▒▒███████▒  ███████████  ██████████ █████  █████ ▒▒▒███████▒  █████  ▒▒█████
      ▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒  ▒▒▒▒▒        ▒▒▒▒▒▒▒    ▒▒▒▒▒    ▒▒▒▒▒    
"""
print_separator
echo "║             CONFIGURAÇÃO DO AMBIENTE VIRTUAL DO CLIENTE                  ║"
print_separator

cd ~ 

print_header "ATUALIZAÇÃO DE PACOTES DO SISTEMA"
echo "Atualizando pacotes (apt update/upgrade)..."

sudo apt update -qq -y 
sudo apt upgrade -qq -y
print_separator

create_target_directory 

install_python 
install_java
install_maven 

clone_repository_python
configure_env_files
setup_python_environment 

clone_repository_java
configure_repository_java 

runJavaEmSegundoPlano
runPythonEmSegundoPlano

print_header "FINALIZAÇÃO DO SETUP"
echo "O script de configuração foi concluído. Verifique o output para erros."
echo "Os repositórios foram clonados em (~/$TARGET_DIR)."
echo "Para ativar o ambiente Python, use: cd ~/$TARGET_DIR/$PYTHON_DIR && source venv/bin/activate"
echo "Para verificar os processos em segundo plano: ps aux | grep -i 'java\|python'"
print_separator
