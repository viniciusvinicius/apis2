# Use uma versão mais estável do Node
FROM node:18-alpine

# Instalar curl para healthcheck
RUN apk add --no-cache curl

# Definir diretório de trabalho
WORKDIR /usr/src/app

# Copiar arquivos de dependências primeiro (para cache do Docker)
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production && npm cache clean --force

# Copiar código da aplicação
COPY . .

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Criar diretório de logs e ajustar permissões
RUN mkdir -p logs && \
    chown -R nodejs:nodejs /usr/src/app

USER nodejs

# Expor porta
EXPOSE 1996

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:1996/health || exit 1

# Comando de inicialização
CMD ["node", "index.js"]
