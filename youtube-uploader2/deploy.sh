#!/bin/bash

# ==============================================
# YouTube Uploader - Script Universal de Deploy
# ==============================================
# Este script pode ser usado por qualquer pessoa
# para fazer deploy da aplicação em seu servidor

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações padrão (ALTERE AQUI para seu repositório)
REPO_URL="https://github.com/viniciusvinicius/apis2.git"
DEPLOY_DIR="/opt/youtube-uploader"
BRANCH="main"

# Função para logs coloridos
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
YouTube Uploader - Script Universal de Deploy

USO:
    $0 [OPÇÕES]

OPÇÕES:
    -r, --repo URL          URL do repositório Git (padrão: detectado automaticamente)
    -d, --dir DIRETÓRIO     Diretório de deploy (padrão: /opt/youtube-uploader)
    -b, --branch BRANCH     Branch para deploy (padrão: main)
    -h, --help              Mostra esta ajuda
    --update-only           Apenas atualiza código, sem recriar containers
    --ssl-only              Apenas configura SSL
    --no-ssl                Pula configuração SSL

EXEMPLOS:
    # Deploy básico
    $0

    # Deploy com repositório específico
    $0 --repo https://github.com/meuusuario/meu-repo.git

    # Apenas atualizar código
    $0 --update-only

    # Deploy em diretório específico
    $0 --dir /home/usuario/youtube-uploader

REQUISITOS:
    - Ubuntu/Debian com sudo
    - Arquivo .env configurado
    - Docker e Docker Compose (serão instalados automaticamente)

EOF
}

# Parse dos argumentos
UPDATE_ONLY=false
SSL_ONLY=false
NO_SSL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO_URL="$2"
            shift 2
            ;;
        -d|--dir)
            DEPLOY_DIR="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        --update-only)
            UPDATE_ONLY=true
            shift
            ;;
        --ssl-only)
            SSL_ONLY=true
            shift
            ;;
        --no-ssl)
            NO_SSL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1. Use --help para ver as opções disponíveis."
            ;;
    esac
done

# Banner
cat << 'EOF'
╔═══════════════════════════════════════════════╗
║        YouTube Uploader - Deploy Script       ║
║              Universal Installation            ║
╚═══════════════════════════════════════════════╝
EOF

log "Iniciando deploy do YouTube Uploader..."
info "Repositório: $REPO_URL"
info "Diretório: $DEPLOY_DIR"
info "Branch: $BRANCH"

# Verificações iniciais
check_requirements() {
    log "Verificando requisitos do sistema..."
    
    # Verificar se não está rodando como root
    if [[ $EUID -eq 0 ]]; then
        error "Este script não deve ser executado como root. Use um usuário com sudo."
    fi
    
    # Verificar se tem sudo
    if ! sudo -n true 2>/dev/null; then
        warn "Este script precisa de privilégios sudo. Você será solicitado a inserir a senha."
    fi
    
    # Verificar sistema operacional
    if ! command -v apt-get &> /dev/null; then
        error "Este script é compatível apenas com sistemas baseados em Debian/Ubuntu"
    fi
    
    log "✅ Verificações iniciais concluídas"
}

# Instalar dependências
install_dependencies() {
    log "Instalando dependências do sistema..."
    
    sudo apt update
    sudo apt install -y curl wget git

    # Instalar Docker se não estiver instalado
    if ! command -v docker &> /dev/null; then
        log "Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        log "✅ Docker instalado"
    else
        log "✅ Docker já instalado"
    fi

    # Instalar Docker Compose se não estiver instalado
    if ! command -v docker-compose &> /dev/null; then
        log "Instalando Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log "✅ Docker Compose instalado"
    else
        log "✅ Docker Compose já instalado"
    fi
}

# Configurar diretório de deploy
setup_deploy_directory() {
    log "Configurando diretório de deploy..."
    
    # Criar diretório se não existir
    sudo mkdir -p $DEPLOY_DIR
    sudo chown $USER:$USER $DEPLOY_DIR
    
    cd $DEPLOY_DIR
    
    # Clonar ou atualizar repositório
    if [ -d ".git" ]; then
        log "Atualizando repositório..."
        git fetch origin
        git checkout $BRANCH
        git pull origin $BRANCH
    else
        log "Clonando repositório..."
        git clone -b $BRANCH $REPO_URL .
    fi
    
    # Criar estrutura de diretórios
    mkdir -p logs ssl backup
    
    log "✅ Diretório configurado"
}

# Configurar arquivo de ambiente
setup_environment() {
    log "Configurando arquivo de ambiente..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            warn "Arquivo .env criado a partir do .env.example"
            warn "⚠️  IMPORTANTE: Configure o arquivo .env antes de continuar!"
            warn "Execute: nano .env"
            
            # Perguntar se quer configurar agora
            read -p "Deseja configurar o .env agora? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                nano .env
            else
                warn "Lembre-se de configurar o .env antes de usar a aplicação!"
            fi
        else
            error "Arquivo .env.example não encontrado. Verifique o repositório."
        fi
    else
        log "✅ Arquivo .env já existe"
    fi
}

# Configurar SSL
setup_ssl() {
    if [ "$NO_SSL" = true ]; then
        log "Pulando configuração SSL conforme solicitado"
        return
    fi
    
    # Carregar variáveis do .env
    if [ -f ".env" ]; then
        export $(grep -v '^#' .env | xargs)
    fi
    
    if [ "$SSL_ENABLED" != "true" ]; then
        log "SSL desabilitado no .env, pulando configuração"
        return
    fi
    
    log "Configurando SSL com Let's Encrypt..."
    
    if [ -z "$DOMAIN" ] || [ -z "$SUBDOMAIN" ] || [ -z "$SSL_EMAIL" ]; then
        error "Configure DOMAIN, SUBDOMAIN e SSL_EMAIL no arquivo .env"
    fi
    
    FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
    
    # Instalar Certbot se necessário
    if ! command -v certbot &> /dev/null; then
        log "Instalando Certbot..."
        sudo apt install -y certbot
    fi
    
    # Verificar se certificado já existe
    if [ ! -f "ssl/fullchain.pem" ]; then
        log "Gerando certificado SSL para $FULL_DOMAIN..."
        
        # Parar nginx se estiver rodando
        docker-compose down nginx 2>/dev/null || true
        
        # Gerar certificado
        sudo certbot certonly --standalone \
            --email $SSL_EMAIL \
            --agree-tos \
            --no-eff-email \
            -d $FULL_DOMAIN
        
        # Copiar certificados
        sudo cp /etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem ssl/
        sudo cp /etc/letsencrypt/live/$FULL_DOMAIN/privkey.pem ssl/
        sudo chown $USER:$USER ssl/*.pem
        
        log "✅ Certificado SSL gerado"
    else
        log "✅ Certificado SSL já existe"
    fi
    
    # Configurar renovação automática
    setup_ssl_renewal
}

# Configurar renovação automática do SSL
setup_ssl_renewal() {
    log "Configurando renovação automática do SSL..."
    
    # Criar script de renovação
    cat > ssl_renew.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
sudo certbot renew --quiet
if [ $? -eq 0 ]; then
    cp /etc/letsencrypt/live/*/fullchain.pem ssl/
    cp /etc/letsencrypt/live/*/privkey.pem ssl/
    chown $USER:$USER ssl/*.pem
    docker-compose restart nginx
fi
EOF
    
    chmod +x ssl_renew.sh
    
    # Adicionar ao crontab se não existir
    if ! crontab -l 2>/dev/null | grep -q "ssl_renew.sh"; then
        (crontab -l 2>/dev/null; echo "0 12 * * * $DEPLOY_DIR/ssl_renew.sh") | crontab -
        log "✅ Renovação automática configurada"
    fi
}

# Deploy da aplicação
deploy_application() {
    log "Fazendo deploy da aplicação..."
    
    # Parar containers existentes
    docker-compose down 2>/dev/null || true
    
    # Construir imagem localmente ou usar do registry
    if [ -f "docker-compose.prod.yml" ]; then
        log "Usando configuração de produção..."
        docker-compose -f docker-compose.prod.yml pull 2>/dev/null || docker-compose build
        docker-compose -f docker-compose.prod.yml up -d
    else
        docker-compose build
        docker-compose up -d
    fi
    
    log "✅ Aplicação deployada"
}

# Verificar se a aplicação está funcionando
verify_deployment() {
    log "Verificando deployment..."
    
    # Aguardar containers iniciarem
    sleep 15
    
    # Verificar se containers estão rodando
    if docker-compose ps | grep -q "Up"; then
        log "✅ Containers estão rodando"
    else
        error "Falha ao iniciar containers. Verifique os logs: docker-compose logs"
    fi
    
    # Verificar health check
    local health_url="http://localhost:${PORT:-1996}/health"
    
    for i in {1..10}; do
        if curl -f $health_url >/dev/null 2>&1; then
            log "✅ Health check passou"
            break
        else
            if [ $i -eq 10 ]; then
                error "Health check falhou após 10 tentativas"
            fi
            log "Aguardando aplicação iniciar... (tentativa $i/10)"
            sleep 5
        fi
    done
}

# Mostrar informações finais
show_completion_info() {
    # Carregar variáveis do .env
    if [ -f ".env" ]; then
        export $(grep -v '^#' .env | xargs)
    fi
    
    cat << EOF

╔═══════════════════════════════════════════════╗
║              DEPLOY CONCLUÍDO! 🎉             ║
╚═══════════════════════════════════════════════╝

📍 INFORMAÇÕES DE ACESSO:
EOF

    if [ "$SSL_ENABLED" = "true" ] && [ -n "$SUBDOMAIN" ] && [ -n "$DOMAIN" ]; then
        echo "   🌐 API URL: https://${SUBDOMAIN}.${DOMAIN}"
        echo "   🏥 Health: https://${SUBDOMAIN}.${DOMAIN}/health"
    else
        echo "   🌐 API URL: http://localhost:${PORT:-1996}"
        echo "   🏥 Health: http://localhost:${PORT:-1996}/health"
    fi

    cat << EOF

🔧 COMANDOS ÚTEIS:
   docker-compose logs -f          # Ver logs
   docker-compose ps               # Status dos containers
   docker-compose restart          # Reiniciar
   ./deploy.sh --update-only       # Atualizar apenas código

📁 ARQUIVOS IMPORTANTES:
   $DEPLOY_DIR/.env               # Configurações
   $DEPLOY_DIR/logs/              # Logs da aplicação
   $DEPLOY_DIR/ssl/               # Certificados SSL

EOF

    if [ "$SSL_ENABLED" = "true" ]; then
        echo "🔒 SSL configurado e renovação automática ativa"
    fi
    
    echo ""
    log "Deploy finalizado com sucesso!"
}

# Função principal
main() {
    if [ "$SSL_ONLY" = true ]; then
        cd $DEPLOY_DIR
        setup_ssl
        exit 0
    fi
    
    if [ "$UPDATE_ONLY" = false ]; then
        check_requirements
        install_dependencies
    fi
    
    setup_deploy_directory
    
    if [ "$UPDATE_ONLY" = false ]; then
        setup_environment
        if [ "$NO_SSL" = false ]; then
            setup_ssl
        fi
    fi
    
    deploy_application
    verify_deployment
    show_completion_info
}

# Executar função principal
main "$@"
