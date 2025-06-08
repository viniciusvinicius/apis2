# 🚀 YouTube Uploader API - Deploy Universal

Esta é uma API para upload de vídeos no YouTube que **qualquer pessoa pode usar** em seu próprio servidor, sem precisar de configurações complexas.

## ⚡ Deploy Rápido (1 comando)

```bash
# 1. Clone o repositório
git clone https://github.com/viniciusvinicius/youtube-uploader2.git
cd SEU_REPOSITORIO

# 2. Execute o script de deploy
chmod +x deploy.sh
./deploy.sh
```

**Pronto!** 🎉 Sua API estará rodando.

## 📋 Pré-requisitos

- **Servidor**: Ubuntu/Debian com acesso sudo
- **Domínio**: Um domínio próprio (ex: `meusite.com`)
- **DNS**: Acesso para configurar subdomínio

## 🔧 Configuração Básica

### 1. Configurar DNS
Crie um registro A no seu provedor de DNS:
```
youtube-api.seudominio.com → IP_DO_SEU_SERVIDOR
```

### 2. Configurar Variáveis
Após rodar o deploy, edite o arquivo `.env`:
```bash
nano .env
```

Configure pelo menos:
```bash
DOMAIN=seudominio.com
SUBDOMAIN=youtube-api
SSL_EMAIL=seu-email@exemplo.com
```

### 3. Reiniciar
```bash
docker-compose restart
```

## 🌍 URLs de Acesso

Após o deploy, sua API estará disponível em:
- **API**: `https://youtube-api.seudominio.com/upload`
- **Health**: `https://youtube-api.seudominio.com/health`

## 🔄 Como Usar no N8N

Configure o nó HTTP Request:
```javascript
Method: POST
URL: https://youtube-api.seudominio.com/upload
Headers:
  Authorization: Bearer {{$json.access_token}}
  Content-Type: application/json

Body:
{
  "filePath": "/tmp/video.mp4",
  "title": "Título do Vídeo",
  "description": "Descrição do vídeo",
  "tags": ["tag1", "tag2"],
  "privacyStatus": "private"
}
```

## 🛠️ Comandos Úteis

### Verificar Status
```bash
docker-compose ps
docker-compose logs -f
```

### Atualizar Código
```bash
./deploy.sh --update-only
```

### Ver Logs
```bash
docker-compose logs youtube-uploader2
```

### Reiniciar Serviços
```bash
docker-compose restart
```

## 🔧 Opções Avançadas do Deploy

```bash
# Deploy com repositório específico
./deploy.sh --repo https://github.com/meuusuario/meu-fork.git

# Deploy em diretório específico
./deploy.sh --dir /home/usuario/minha-api

# Deploy sem SSL (apenas HTTP)
./deploy.sh --no-ssl

# Apenas configurar SSL
./deploy.sh --ssl-only

# Ver todas as opções
./deploy.sh --help
```

## 🏗️ Para Desenvolvedores

### Fork do Repositório
1. Faça fork deste repositório
2. Configure GitHub Actions (opcional)
3. Usuários poderão usar seu fork:
   ```bash
   ./deploy.sh --repo https://github.com/seuusuario/seu-fork.git
   ```

### Build Automático
O GitHub Actions faz build automático e publica no GitHub Container Registry:
- Qualquer push → nova imagem
- Usuários sempre pegam a versão mais recente

### Configurações do Registry
No `.env.example`, altere:
```bash
DOCKER_IMAGE=ghcr.io/seuusuario/seurepositorio/youtube-uploader2:latest
```

## 🔒 Segurança Automática

### SSL/HTTPS
- Certificados Let's Encrypt automáticos
- Renovação automática configurada
- Redirecionamento HTTP → HTTPS

### Rate Limiting
- 10 requests/segundo por IP
- Proteção contra abuso
- Configurável no nginx.conf

### Headers de Segurança
Headers configurados automaticamente:
- X-Frame-Options
- X-XSS-Protection  
- X-Content-Type-Options
- Content-Security-Policy

### Firewall
Configure seu firewall (UFW):
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

## 📊 Monitoramento

### Health Check
```bash
curl https://youtube-api.seudominio.com/health
```

Resposta esperada:
```json
{
  "status": "ok",
  "timestamp": "2025-06-08T...",
  "uptime": 3600,
  "environment": "production",
  "port": 1996
}
```

### Logs da Aplicação
```bash
# Ver logs em tempo real
docker-compose logs -f

# Ver logs específicos do uploader
docker-compose logs youtube-uploader2

# Ver logs do nginx
docker-compose logs nginx
```

### Verificar Certificados SSL
```bash
# Status do certificado
sudo certbot certificates

# Testar renovação
sudo certbot renew --dry-run
```

## 🆘 Solução de Problemas

### Problema: 502 Bad Gateway
```bash
# 1. Verificar se containers estão rodando
docker-compose ps

# 2. Ver logs para erros
docker-compose logs

# 3. Reiniciar serviços
docker-compose restart

# 4. Se persistir, reconstruir
docker-compose down
docker-compose up -d --build
```

### Problema: SSL/HTTPS não funciona
```bash
# 1. Verificar certificados
ls -la ssl/

# 2. Verificar DNS
nslookup youtube-api.seudominio.com

# 3. Verificar firewall
sudo ufw status

# 4. Reconfigurar SSL
./deploy.sh --ssl-only
```

### Problema: Upload muito lento/timeout
Editar `nginx.conf`:
```nginx
# Aumentar timeouts
proxy_connect_timeout 1200s;
proxy_send_timeout 1200s;
proxy_read_timeout 1200s;

# Aumentar tamanho máximo
client_max_body_size 5G;
```

Depois reiniciar:
```bash
docker-compose restart nginx
```

### Problema: Erro de permissão de arquivo
```bash
# Verificar permissões
ls -la /tmp/

# Ajustar se necessário
sudo chmod 755 /tmp/
sudo chown $USER:$USER logs/
```

## 🌐 Configurações de Provedor

### Cloudflare
Se usar Cloudflare, configure no `.env`:
```bash
USE_CLOUDFLARE=true
TRUST_PROXY=true
```

### AWS/DigitalOcean/Vultr
Certifique-se de:
- Liberar portas 80 e 443 no Security Group
- Configurar DNS corretamente
- Ter IP público estático

### Nginx Proxy Manager
Se já usar NPM, desabilite o nginx interno:
```bash
# No docker-compose.yml, comente a seção nginx
# Ou use apenas:
docker-compose up youtube-uploader2
```

## 🔄 Atualizações

### Atualização Automática via GitHub
Quando você fizer push para o repositório:
1. GitHub Actions constrói nova imagem
2. Publica no Container Registry
3. Execute no servidor:
   ```bash
   ./deploy.sh --update-only
   ```

### Atualização Manual
```bash
cd /opt/youtube-uploader
git pull
docker-compose build
docker-compose up -d
```

## 🤝 Contribuindo

### Para Usuários
- Reporte bugs via Issues
- Sugira melhorias
- Compartilhe casos de uso

### Para Desenvolvedores
1. Fork o repositório
2. Crie branch para feature: `git checkout -b feature/nova-funcionalidade`
3. Commit suas mudanças: `git commit -m 'Adiciona nova funcionalidade'`
4. Push para branch: `git push origin feature/nova-funcionalidade`
5. Abra Pull Request

## 📄 Licença

Este projeto é open source. Você pode:
- ✅ Usar comercialmente
- ✅ Modificar o código
- ✅ Distribuir
- ✅ Usar em projetos privados

## 💬 Suporte

- **Issues**: Para bugs e problemas técnicos
- **Discussions**: Para dúvidas e ideias
- **Wiki**: Documentação detalhada

## 🙏 Agradecimentos

Este projeto foi criado para ser simples e acessível. Obrigado a todos que contribuem para torná-lo melhor!

---

**📞 Precisa de ajuda?** Abra uma Issue que respondemos rapidamente!

## 📚 Documentação Adicional

- [🚀 Guia Rápido](QUICK_START.md) - Deploy em 3 passos
- [📋 Configuração Detalhada](.env.example) - Todas as variáveis disponíveis
