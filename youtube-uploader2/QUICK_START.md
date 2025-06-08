# ⚡ Guia Rápido - YouTube Uploader API

## 🎯 Deploy em 3 Passos

### 1️⃣ Preparar Servidor
```bash
# Conectar ao seu servidor (VPS/Cloud)
ssh usuario@seu-servidor.com

# Atualizar sistema
sudo apt update && sudo apt upgrade -y
```

### 2️⃣ Configurar DNS
No seu provedor de DNS, adicione:
```
Tipo: A
Nome: youtube-api
Valor: IP_DO_SEU_SERVIDOR
TTL: 300
```

### 3️⃣ Deploy Automático
```bash
# Clonar e executar
git clone https://github.com/viniciusvinicius/SEU_REPOSITORIO.git
cd SEU_REPOSITORIO
chmod +x deploy.sh
./deploy.sh
```

## ⚙️ Configuração Mínima

Quando solicitado, configure o `.env`:
```bash
DOMAIN=seudominio.com
SUBDOMAIN=youtube-api  
SSL_EMAIL=seu-email@dominio.com
```

## ✅ Teste Rápido

```bash
# Verificar se está funcionando
curl https://youtube-api.seudominio.com/health
```

**Pronto!** Sua API está funcionando em `https://youtube-api.seudominio.com`

## 🔌 Usar no N8N

1. **HTTP Request Node**
2. **Method**: POST
3. **URL**: `https://youtube-api.seudominio.com/upload`
4. **Headers**: 
   ```
   Authorization: Bearer SEU_TOKEN_YOUTUBE
   Content-Type: application/json
   ```
5. **Body**:
   ```json
   {
     "filePath": "/tmp/video.mp4",
     "title": "Meu Vídeo",
     "description": "Descrição do vídeo",
     "privacyStatus": "private"
   }
   ```

## 🆘 Problemas?

```bash
# Ver logs
docker-compose logs -f

# Reiniciar
docker-compose restart

# Status
docker-compose ps
```

---
**💡 Dica**: Para documentação completa, veja [README.md](README.md)
