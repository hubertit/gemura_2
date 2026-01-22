import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import * as https from 'https';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Trust proxy to get correct client IP
  const expressApp = app.getHttpAdapter().getInstance();
  expressApp.set('trust proxy', true);

  // Security - Helmet configuration
  // Disable CSP for Swagger docs path to avoid asset loading issues
  app.use((req, res, next) => {
    if (req.path.startsWith('/api/docs')) {
      return next();
    }
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'", "https://cdnjs.cloudflare.com"],
          imgSrc: ["'self'", "data:", "https:"],
          connectSrc: ["'self'", "https://cdnjs.cloudflare.com"],
          fontSrc: ["'self'"],
          objectSrc: ["'none'"],
          mediaSrc: ["'self'"],
          frameSrc: ["'none'"],
        },
      },
      crossOriginEmbedderPolicy: false,
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true,
      },
    })(req, res, next);
  });

  // CORS configuration
  // Allow all origins if CORS_ORIGIN is set to '*' or in development mode
  const allowAllOrigins = process.env.CORS_ORIGIN === '*' || process.env.NODE_ENV !== 'production';

  if (allowAllOrigins) {
    console.log('🌐 CORS: Allowing all origins');
    app.enableCors({
      origin: true, // Allow all origins
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
      exposedHeaders: ['Content-Type', 'Authorization'],
    });
  } else {
    const allowedOrigins = process.env.CORS_ORIGIN
      ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim())
      : ['http://localhost:3101', 'http://localhost:3100'];

    console.log('🌐 CORS Allowed Origins:', allowedOrigins);

    app.enableCors({
      origin: (origin, callback) => {
        if (!origin) {
          // Allow requests without an Origin header (e.g. curl, server-to-server, health checks).
          // Browsers always send Origin for CORS requests; enforcing Origin here can break non-browser clients.
          return callback(null, true);
        }

        if (allowedOrigins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error(`Not allowed by CORS. Origin: ${origin}`));
        }
      },
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
      exposedHeaders: ['Content-Type', 'Authorization'],
    });
  }

  // Media proxy route (MUST be before API prefix to avoid /api/media)
  // Use a catch-all route for /media/*
  expressApp.use('/media', async (req, res, next) => {
    // Extract path after /media/
    const path = req.path.replace('/media', '').replace(/^\//, '');
    
    if (!path) {
      return res.status(400).json({
        code: 400,
        status: 'error',
        message: 'Media path is required',
      });
    }
    
    const targetUrl = `https://www.kigalitoday.com/${path}`;
    
    https.get(targetUrl, (proxyRes) => {
      res.setHeader('Content-Type', proxyRes.headers['content-type'] || 'image/jpeg');
      res.setHeader('Cache-Control', 'public, max-age=31536000');
      res.setHeader('Access-Control-Allow-Origin', '*');
      
      if (proxyRes.statusCode === 200) {
        proxyRes.pipe(res);
      } else {
        res.status(proxyRes.statusCode || 500).json({
          code: proxyRes.statusCode || 500,
          status: 'error',
          message: `Failed to fetch media: ${proxyRes.statusCode}`,
        });
      }
    }).on('error', (error) => {
      res.status(502).json({
        code: 502,
        status: 'error',
        message: `Failed to proxy media: ${error.message}`,
      });
    });
  });

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // API prefix
  app.setGlobalPrefix('api');

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('Gemura API')
    .setDescription('Gemura Financial Services API Documentation')
    .setVersion('2.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    customCssUrl: 'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui.min.css',
    customJs: [
      'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui-bundle.js',
      'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui-standalone-preset.js',
    ],
  });

  const port = process.env.PORT || 3004;
  await app.listen(port);
  console.log(`🚀 Gemura API running on http://localhost:${port}`);
  console.log(`📚 API Docs: http://localhost:${port}/api/docs`);
}
bootstrap();

