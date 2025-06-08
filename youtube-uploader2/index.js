require('dotenv').config();
const express = require('express');
const fs = require('fs');
const { google } = require('googleapis');

const app = express();

// Middleware para parsing JSON com limite maior
app.use(express.json({ limit: '50mb' }));

// Middleware de logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// ────────── Health-check melhorado ──────────
app.get('/health', (req, res) => {
  const healthCheck = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 1996
  };
  
  console.log('Health check requested:', healthCheck);
  res.json(healthCheck);
});

// ────────── Endpoint de teste ──────────
app.get('/', (req, res) => {
  res.json({ 
    message: 'YouTube Uploader API is running',
    endpoints: {
      health: '/health',
      upload: '/upload (POST)'
    }
  });
});

// ────────── Upload de vídeo com melhor error handling ───────
app.post('/upload', async (req, res) => {
  console.log('Upload request received');
  
  try {
    // 1. Validar Authorization header
    const authHeader = req.headers.authorization || '';
    const accessToken = authHeader.startsWith('Bearer ')
      ? authHeader.split(' ')[1]
      : null;

    if (!accessToken) {
      console.error('Missing or malformed authorization header');
      return res.status(401).json({ 
        error: 'Authorization header ausente ou mal-formado',
        details: 'Formato esperado: Bearer <access_token>'
      });
    }

    // 2. Validar campos obrigatórios
    const {
      filePath,
      title,
      description = '',
      tags = [],
      privacyStatus = 'private',
      publishAt,
      defaultLanguage,
      defaultAudioLanguage
    } = req.body;

    console.log('Request body received:', {
      filePath: filePath ? 'PROVIDED' : 'MISSING',
      title: title ? 'PROVIDED' : 'MISSING',
      description: description ? 'PROVIDED' : 'EMPTY',
      tags: Array.isArray(tags) ? `${tags.length} tags` : 'NOT_ARRAY',
      privacyStatus,
      publishAt: publishAt || 'NOT_SET'
    });

    if (!filePath || !title) {
      console.error('Missing required fields:', { filePath: !!filePath, title: !!title });
      return res.status(400).json({ 
        error: 'Campos obrigatórios ausentes',
        missing: {
          filePath: !filePath,
          title: !title
        }
      });
    }

    // 3. Verificar se o arquivo existe
    if (!fs.existsSync(filePath)) {
      console.error('File not found:', filePath);
      return res.status(400).json({ 
        error: 'Arquivo não encontrado',
        filePath 
      });
    }

    console.log('File exists, proceeding with upload');

    // 4. Configurar cliente OAuth2
    const oauth2Client = new google.auth.OAuth2();
    oauth2Client.setCredentials({ access_token: accessToken });
    const youtube = google.youtube({ version: 'v3', auth: oauth2Client });

    // 5. Preparar dados do vídeo
    const status = { privacyStatus };
    if (publishAt) status.publishAt = publishAt;

    const snippet = { title, description, tags };
    if (defaultLanguage) snippet.defaultLanguage = defaultLanguage;
    if (defaultAudioLanguage) snippet.defaultAudioLanguage = defaultAudioLanguage;

    console.log('Starting YouTube upload...');

    // 6. Fazer upload
    const response = await youtube.videos.insert({
      part: ['snippet', 'status'],
      requestBody: {
        snippet,
        status
      },
      media: {
        body: fs.createReadStream(filePath)
      }
    });

    const videoId = response.data.id;
    const result = {
      success: true,
      id: videoId,
      url: `https://youtu.be/${videoId}`,
      uploadedAt: new Date().toISOString()
    };

    console.log('Upload successful:', result);
    res.json(result);

  } catch (err) {
    console.error('Upload error:', {
      message: err.message,
      errors: err?.errors,
      code: err?.code,
      status: err?.status,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });

    const errorResponse = {
      error: 'Erro no upload do vídeo',
      message: err?.errors?.[0]?.message || err.message,
      timestamp: new Date().toISOString()
    };

    // Diferentes códigos de erro baseados no tipo de erro
    if (err.code === 401 || err.message.includes('unauthorized')) {
      res.status(401).json({ ...errorResponse, error: 'Token de acesso inválido ou expirado' });
    } else if (err.code === 403) {
      res.status(403).json({ ...errorResponse, error: 'Permissões insuficientes' });
    } else if (err.code === 404) {
      res.status(404).json({ ...errorResponse, error: 'Recurso não encontrado' });
    } else {
      res.status(500).json(errorResponse);
    }
  }
});

// ────────── Error handling middleware ──────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Erro interno do servidor',
    timestamp: new Date().toISOString()
  });
});

// ────────── 404 handler ──────────
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint não encontrado',
    path: req.path,
    method: req.method
  });
});

// ────────── Inicializar servidor ───────
const PORT = process.env.PORT || 1996;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 YouTube-uploader listening on port ${PORT}`);
  console.log(`📍 Server started at ${new Date().toISOString()}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});
