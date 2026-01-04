"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const bcrypt = __importStar(require("bcrypt"));
let AuthService = class AuthService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async login(loginDto, ipAddress, userAgent) {
        const { identifier, password } = loginDto;
        const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
        const field = isEmail ? 'email' : 'phone';
        const value = isEmail ? identifier.toLowerCase() : identifier.replace(/\D/g, '');
        const user = await this.prisma.user.findFirst({
            where: {
                [field]: value,
            },
        });
        if (!user) {
            throw new common_1.UnauthorizedException({
                code: 401,
                status: 'error',
                message: 'Invalid credentials.',
            });
        }
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) {
            throw new common_1.UnauthorizedException({
                code: 401,
                status: 'error',
                message: 'Invalid credentials.',
            });
        }
        const userAccounts = await this.prisma.userAccount.findMany({
            where: {
                user_id: user.id,
                status: 'active',
            },
            include: {
                account: true,
            },
            orderBy: {
                created_at: 'desc',
            },
        });
        const accounts = userAccounts
            .filter((ua) => ua.account && ua.account.status === 'active')
            .map((ua) => ({
            account_id: ua.account.id,
            account_code: ua.account.code,
            account_name: ua.account.name,
            account_type: ua.account.type,
            account_status: ua.account.status,
            account_created_at: ua.account.created_at,
            role: ua.role,
            permissions: ua.permissions ? (typeof ua.permissions === 'string' ? JSON.parse(ua.permissions) : ua.permissions) : null,
            user_account_status: ua.status,
            access_granted_at: ua.created_at,
            is_default: user.default_account_id === ua.account.id,
        }));
        const defaultAccount = accounts.find((a) => a.is_default);
        const defaultAccountData = defaultAccount
            ? {
                id: defaultAccount.account_id,
                code: defaultAccount.account_code,
                name: defaultAccount.account_name,
                type: defaultAccount.account_type,
            }
            : null;
        const profileFields = [
            'name',
            'email',
            'phone',
            'province',
            'district',
            'sector',
            'cell',
            'village',
            'id_number',
            'id_front_photo_url',
            'id_back_photo_url',
            'selfie_photo_url',
        ];
        let completedFields = 0;
        for (const field of profileFields) {
            if (user[field]) {
                completedFields++;
            }
        }
        const profileCompletion = Math.round((completedFields / profileFields.length) * 100);
        await this.prisma.user.update({
            where: { id: user.id },
            data: {
                last_login: new Date(),
                last_login_ip: ipAddress,
                last_login_device: userAgent,
            },
        });
        return {
            code: 200,
            status: 'success',
            message: 'Login successful.',
            data: {
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    account_type: user.account_type,
                    status: user.status,
                    token: user.token,
                },
                account: defaultAccountData,
                accounts,
                total_accounts: accounts.length,
                profile_completion: profileCompletion,
            },
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AuthService);
//# sourceMappingURL=auth.service.js.map