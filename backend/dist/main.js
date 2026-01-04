"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const helmet_1 = __importDefault(require("helmet"));
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    const expressApp = app.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', true);
    app.use((0, helmet_1.default)({
        contentSecurityPolicy: {
            directives: {
                defaultSrc: ["'self'"],
                styleSrc: ["'self'", "'unsafe-inline'"],
                scriptSrc: ["'self'"],
                imgSrc: ["'self'", "data:", "https:"],
                connectSrc: ["'self'"],
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
    }));
    const allowedOrigins = process.env.CORS_ORIGIN
        ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim())
        : ['http://localhost:3101', 'http://localhost:3100'];
    console.log('🌐 CORS Allowed Origins:', allowedOrigins);
    app.enableCors({
        origin: (origin, callback) => {
            if (!origin) {
                if (process.env.NODE_ENV === 'development') {
                    return callback(null, true);
                }
                return callback(new Error('Origin is required in production'));
            }
            if (allowedOrigins.includes(origin)) {
                callback(null, true);
            }
            else if (allowedOrigins.includes('*')) {
                console.warn('⚠️  CORS: Wildcard (*) is enabled - this is insecure!');
                callback(null, true);
            }
            else {
                callback(new Error(`Not allowed by CORS. Origin: ${origin}`));
            }
        },
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
        exposedHeaders: ['Content-Type', 'Authorization'],
    });
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
        transformOptions: {
            enableImplicitConversion: true,
        },
    }));
    app.setGlobalPrefix('api');
    const config = new swagger_1.DocumentBuilder()
        .setTitle('Gemura API')
        .setDescription('Gemura Financial Services API Documentation')
        .setVersion('2.0')
        .addBearerAuth()
        .build();
    const document = swagger_1.SwaggerModule.createDocument(app, config);
    swagger_1.SwaggerModule.setup('api/docs', app, document);
    const port = process.env.PORT || 3003;
    await app.listen(port);
    console.log(`🚀 Gemura API running on http://localhost:${port}`);
    console.log(`📚 API Docs: http://localhost:${port}/api/docs`);
}
bootstrap();
//# sourceMappingURL=main.js.map