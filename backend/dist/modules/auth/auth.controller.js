"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const auth_service_1 = require("./auth.service");
const login_dto_1 = require("./dto/login.dto");
const auth_response_dto_1 = require("./dto/auth-response.dto");
let AuthController = class AuthController {
    constructor(authService) {
        this.authService = authService;
    }
    async login(loginDto, request) {
        const ipAddress = request.ip || request.headers['x-forwarded-for'] || request.connection.remoteAddress;
        const userAgent = request.headers['user-agent'];
        return this.authService.login(loginDto, ipAddress, userAgent);
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('login'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({
        summary: 'User login',
        description: 'Authenticate user with email/phone and password. Returns user data, accounts, and authentication token.',
    }),
    (0, swagger_1.ApiBody)({
        type: login_dto_1.LoginDto,
        description: 'User credentials',
        examples: {
            emailLogin: {
                summary: 'Login with email',
                value: {
                    identifier: 'user@example.com',
                    password: 'SecurePassword123!',
                },
            },
            phoneLogin: {
                summary: 'Login with phone',
                value: {
                    identifier: '250788123456',
                    password: 'SecurePassword123!',
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Login successful. Returns user data, accounts, and authentication token.',
        type: auth_response_dto_1.AuthResponseDto,
        example: {
            code: 200,
            status: 'success',
            message: 'Login successful.',
            data: {
                user: {
                    id: 'uuid-here',
                    name: 'John Doe',
                    email: 'user@example.com',
                    phone: '250788123456',
                    account_type: 'mcc',
                    status: 'active',
                    token: 'auth-token-here',
                },
                account: {
                    id: 'account-uuid',
                    code: 'ACC001',
                    name: 'Main Account',
                    type: 'tenant',
                },
                accounts: [],
                total_accounts: 1,
                profile_completion: 75,
            },
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'Invalid request - missing or invalid fields',
        example: {
            code: 400,
            status: 'error',
            message: 'Email/phone and password are required.',
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid credentials',
        example: {
            code: 401,
            status: 'error',
            message: 'Invalid credentials.',
        },
    }),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [login_dto_1.LoginDto, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "login", null);
exports.AuthController = AuthController = __decorate([
    (0, swagger_1.ApiTags)('Authentication'),
    (0, common_1.Controller)('auth'),
    __metadata("design:paramtypes", [auth_service_1.AuthService])
], AuthController);
//# sourceMappingURL=auth.controller.js.map