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
exports.AccountsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let AccountsService = class AccountsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getUserAccounts(user) {
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
            permissions: ua.permissions
                ? typeof ua.permissions === 'string'
                    ? JSON.parse(ua.permissions)
                    : ua.permissions
                : null,
            user_account_status: ua.status,
            access_granted_at: ua.created_at,
            is_default: user.default_account_id === ua.account.id,
        }));
        return {
            code: 200,
            status: 'success',
            message: 'User accounts fetched successfully.',
            data: {
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    default_account_id: user.default_account_id,
                },
                accounts,
                total_accounts: accounts.length,
            },
        };
    }
    async switchAccount(user, switchDto) {
        const { account_id } = switchDto;
        const userAccount = await this.prisma.userAccount.findFirst({
            where: {
                user_id: user.id,
                account_id: account_id,
                status: 'active',
            },
            include: {
                account: true,
            },
        });
        if (!userAccount || !userAccount.account || userAccount.account.status !== 'active') {
            throw new common_1.ForbiddenException({
                code: 403,
                status: 'error',
                message: 'Access denied. You don\'t have permission to access this account.',
            });
        }
        const updatedUser = await this.prisma.user.update({
            where: { id: user.id },
            data: {
                default_account_id: account_id,
            },
        });
        return {
            code: 200,
            status: 'success',
            message: 'Default account switched successfully.',
            data: {
                user: {
                    id: updatedUser.id,
                    name: updatedUser.name,
                    default_account_id: updatedUser.default_account_id,
                },
                account: {
                    id: userAccount.account.id,
                    code: userAccount.account.code,
                    name: userAccount.account.name,
                    type: userAccount.account.type,
                },
            },
        };
    }
};
exports.AccountsService = AccountsService;
exports.AccountsService = AccountsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AccountsService);
//# sourceMappingURL=accounts.service.js.map