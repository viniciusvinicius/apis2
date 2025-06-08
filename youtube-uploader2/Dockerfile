# Use uma versão mais estável do Node
FROM node:18-alpine

# Instalar curl para healthcheck
RUN apk add --no-cache curl

# Definir diretório de trabalho
WORKDIR /usr/src/app

# Copiar todo o código primeiro
COPY . .

# Instalar dependências - usar npm install em vez de npm ci
RUN npm install --production && npm cache clean --force

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
