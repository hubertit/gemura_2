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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TokenGuard = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let TokenGuard = class TokenGuard {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        let token;
        if (request.body?.token) {
            token = request.body.token;
        }
        else if (request.query?.token) {
            token = request.query.token;
        }
        else if (request.headers?.authorization) {
            const authHeader = request.headers.authorization;
            if (authHeader.startsWith('Bearer ')) {
                token = authHeader.substring(7);
            }
        }
        if (!token) {
            throw new common_1.UnauthorizedException({
                code: 401,
                status: 'error',
                message: 'Access denied. Token is required.',
            });
        }
        const user = await this.prisma.user.findFirst({
            where: { token },
            include: {
                user_accounts: {
                    where: { status: 'active' },
                    include: {
                        account: true,
                    },
                },
            },
        });
        if (!user || user.status !== 'active') {
            throw new common_1.UnauthorizedException({
                code: 401,
                status: 'error',
                message: 'Invalid or expired token.',
            });
        }
        request.user = user;
        request.token = token;
        return true;
    }
};
exports.TokenGuard = TokenGuard;
exports.TokenGuard = TokenGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], TokenGuard);
//# sourceMappingURL=token.guard.js.map