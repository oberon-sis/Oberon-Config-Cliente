#!/bin/bash
TARGET_DIR="cliente"
PYTHON_DIR="Oberon-Coleta-Python"
JAVA_DIR="Oberon-Coleta-Java"

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

install_dependencies() {
    print_header "INSTALAÇÃO DE DEPENDÊNCIAS DO SISTEMA"
    echo "Verificando e instalando Python3, venv, Java 17, Maven e nohup (coreutils)..."
    
    if ! command -v python3 &> /dev/null; then sudo apt install python3 -y; fi
    sudo apt install python3-venv -y
    
    if ! command -v java &> /dev/null || ! java -version 2>&1 | grep "version \"17" &> /dev/null; then sudo apt install openjdk-17-jdk -y; fi
    
    if ! command -v mvn &> /dev/null; then sudo apt install maven -y; fi
    
    if ! command -v nohup &> /dev/null; then sudo apt install coreutils -y; fi
    
    echo "Todas as dependências (Python, Java, Maven, nohup) verificadas/instaladas."
    print_separator
}

clone_repository_python() {
    print_header "CLONAGEM DO REPOSITÓRIO PYTHON"
    echo "Clonando repositório Python de $PYTHON_REPO_URL em $(pwd)/$PYTHON_DIR..."
    if [ ! -d "$PYTHON_DIR" ]; then
        git clone "$PYTHON_REPO_URL" "$PYTHON_DIR"
        if [ $? -ne 0 ]; then echo "ERRO: Falha ao clonar Python."; fi
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
        
        if [ -d "venv" ] && [ -f "requirements.txt" ]; then
            echo "Instalando dependências..."
            ./venv/bin/pip install -r requirements.txt
            if [ $? -ne 0 ]; then echo "ERRO: Falha ao instalar dependências Python."; fi
        else
            echo "AVISO: requirements.txt não encontrado ou venv falhou."
        fi
        cd ..
    else
        echo "AVISO: Diretório Python não encontrado."
    fi
    print_separator
}

configure_env_files() {
    print_header "CONFIGURAÇÃO DE ARQUIVOS DE AMBIENTE (.ENV)"
    ENV_FILE="$PYTHON_DIR/.env"
    if [ ! -f "$ENV_FILE" ]; then
        cat << EOF > "$ENV_FILE"
USER_DB=ClienteOberon
PASSWORD_DB=ClienteOberon123
HOST_DB=221.72.209.164
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
    if [ ! -d "$JAVA_DIR" ]; then
        git clone "$JAVA_REPO_URL" "$JAVA_DIR"
        if [ $? -ne 0 ]; then echo "ERRO: Falha ao clonar Java."; fi
    else
        echo "Diretório $JAVA_DIR já existe. Pulando a clonagem."
    fi
    print_separator
}

configure_repository_java(){
    print_header "COMPILAÇÃO DO PROJETO JAVA (MAVEN)"
    # JAVA_JAR_PATH="../../target/looca-api-1.0.0-jar-with-dependencies.jar"
    JAVA_JAR_PATH="Oberon-Coleta-Java/looca-api/target/looca-api-1.0.0-jar-with-dependencies.jar"

    if [ -f "$JAVA_JAR_PATH" ]; then
        echo "AVISO: O arquivo JAR final já existe. Pulando a compilação Maven."
        cd ../..
        print_separator
        return 0
    fi
    
    if [ -d "$JAVA_DIR" ] && [ -d "$JAVA_DIR/looca-api" ]; then
        cd "$JAVA_DIR/looca-api"
        echo "Executando 'mvn clean install' em $(pwd)..."
        mvn clean install 
        if [ $? -ne 0 ]; then echo "ERRO: Falha no 'mvn clean install'."; fi
        cd ../..
    else
        echo "AVISO: Diretório Java ou subdiretório 'looca-api' não encontrado. Pulando compilação."
    fi
    print_separator
}

runJavaEmSegundoPlano(){
    print_header "EXECUÇÃO DO PROJETO JAVA EM SEGUNDO PLANO"
    
    JAVA_JAR_PATH="$JAVA_DIR/looca-api/target/looca-api-1.0.0-jar-with-dependencies.jar"
    LOG_FILE="$JAVA_DIR/oberon_java.log"

    if [ -f "$JAVA_JAR_PATH" ]; then
        nohup java -jar "$JAVA_JAR_PATH" > "$LOG_FILE" 2>&1 &
        echo "Iniciado (PID: $!). Logs em: $LOG_FILE"
    else
        echo "ERRO: Arquivo JAR ($JAVA_JAR_PATH) não encontrado. A execução falhou."
    fi
    print_separator
}

runPythonEmSegundoPlano(){
    print_header "EXECUÇÃO DO PROJETO PYTHON EM SEGUNDO PLANO"

    PYTHON_SCRIPT_PATH="$PYTHON_DIR/main.py"
    PYTHON_VENV_PYTHON="$PYTHON_DIR/venv/bin/python"
    LOG_FILE="$PYTHON_DIR/oberon_python.log"

    if [ -f "$PYTHON_SCRIPT_PATH" ] && [ -f "$PYTHON_VENV_PYTHON" ]; then
        nohup "$PYTHON_VENV_PYTHON" "$PYTHON_SCRIPT_PATH" > "$LOG_FILE" 2>&1 &
        echo "Iniciado (PID: $!). Logs em: $LOG_FILE"
    else
        echo "ERRO: Script Python ou VENV não encontrado. A execução falhou."
    fi
    print_separator
}

# ------------------------------------------------------------------------------
# Início do Script Principal
# ------------------------------------------------------------------------------
print_separator
echo "║           SCRIPT DE CONFIGURAÇÃO INICIAL DA OBERON                     ║"
print_separator
echo """
     ███████     ███████████   ██████████  ███████████       ███████     ██████   █████ 
   ███▒▒▒▒▒███  ▒▒███▒▒▒▒▒███ ▒▒███▒▒▒▒▒█ ▒▒███▒▒▒▒▒███    ███▒▒▒▒▒███  ▒▒██████ ▒▒███   
  ███     ▒▒███  ▒███    ▒███  ▒███  █ ▒   ▒███    ▒███   ███     ▒▒███  ▒███▒███ ▒███  
 ▒███      ▒███  ▒██████████   ▒██████     ▒██████████   ▒███      ▒███  ▒███▒▒███▒███  
 ▒███      ▒███  ▒███▒▒▒▒▒███  ▒███▒▒█     ▒███▒▒▒▒▒███  ▒███      ▒███  ▒███ ▒▒██████  
 ▒▒███     ███   ▒███    ▒███  ▒███ ▒   █  ▒███    ▒███  ▒▒███     ███   ▒███  ▒▒█████  
 ▒▒▒███████▒    ███████████   ██████████  █████   █████  ▒▒▒███████▒    █████  ▒▒█████  
  ▒▒▒▒▒▒▒     ▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒   ▒▒▒▒▒     ▒▒▒▒▒▒▒     ▒▒▒▒▒    ▒▒▒▒▒      
"""
print_separator
echo "║           CONFIGURAÇÃO DO AMBIENTE VIRTUAL DO CLIENTE                  ║"
print_separator

cd ~ 

print_header "ATUALIZAÇÃO DE PACOTES DO SISTEMA"
sudo apt update -qq -y 
sudo apt upgrade -qq -y
print_separator

create_target_directory 

install_dependencies 

clone_repository_python
configure_env_files
setup_python_environment 

clone_repository_java
configure_repository_java 

runJavaEmSegundoPlano
runPythonEmSegundoPlano

print_header "FINALIZAÇÃO E INSPEÇÃO DE LOGS DE ERRO"
echo "O script foi concluído. As aplicações estão rodando em segundo plano e logs foram criados."
echo "======================================================================================="
echo ">> INSPECIONANDO ÚLTIMAS 20 LINHAS DO LOG PYTHON (Possível erro de DB) <<"
echo "======================================================================================="
echo "Conteúdo do log em: $TARGET_DIR/$PYTHON_DIR/oberon_python.log"
echo "---------------------------------------------------------------------------------------"
tail -n 20 $PYTHON_DIR/oberon_python.log
echo "---------------------------------------------------------------------------------------"

print_separator
echo ">> INSPECIONANDO ÚLTIMAS 20 LINHAS DO LOG JAVA (Possível erro de Coleta/Setup) <<"
echo "======================================================================================="
echo "Conteúdo do log em: $TARGET_DIR/$JAVA_DIR/oberon_java.log"
echo "---------------------------------------------------------------------------------------"
tail -n 20 $JAVA_DIR/oberon_java.log
echo "---------------------------------------------------------------------------------------"
print_separator

echo "Terminal liberado. Use 'ps aux | grep -i java' ou 'ps aux | grep -i python' para verificar os processos."
echo "Use 'tail -f [caminho do log]' para monitorar em tempo real após ligar o banco de dados."
print_separator