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
exports.WalletsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let WalletsService = class WalletsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getWallets(user) {
        if (!user.default_account_id) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No valid default account found. Please set a default account.',
            });
        }
        const wallets = await this.prisma.wallet.findMany({
            where: {
                account_id: user.default_account_id,
            },
            include: {
                account: true,
            },
        });
        if (wallets.length === 0) {
            throw new common_1.NotFoundException({
                code: 404,
                status: 'error',
                message: 'No wallets found for this account.',
            });
        }
        const formattedWallets = wallets.map((wallet) => ({
            wallet_code: wallet.code,
            type: wallet.type,
            is_joint: wallet.is_joint,
            is_default: wallet.is_default,
            balance: Number(wallet.balance),
            currency: wallet.currency,
            status: wallet.status,
            account: {
                code: wallet.account.code,
                name: wallet.account.name,
                type: wallet.account.type,
            },
        }));
        return {
            code: 200,
            status: 'success',
            message: 'Wallets fetched successfully.',
            data: formattedWallets,
        };
    }
};
exports.WalletsService = WalletsService;
exports.WalletsService = WalletsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], WalletsService);
//# sourceMappingURL=wallets.service.js.map