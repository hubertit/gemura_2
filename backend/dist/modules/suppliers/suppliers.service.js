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
exports.SuppliersService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const bcrypt = __importStar(require("bcrypt"));
const crypto_1 = require("crypto");
let SuppliersService = class SuppliersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createOrUpdateSupplier(user, createDto) {
        const { name, phone, price_per_liter, email, nid, address } = createDto;
        if (!user.default_account_id) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No valid default account found. Please set a default account.',
            });
        }
        const customerAccountId = user.default_account_id;
        const normalizedPhone = phone.replace(/\D/g, '');
        const existingSupplier = await this.prisma.user.findFirst({
            where: {
                OR: [
                    { phone: normalizedPhone },
                    ...(email ? [{ email: email.toLowerCase() }] : []),
                    ...(nid ? [{ nid }] : []),
                ],
            },
            include: {
                user_accounts: {
                    where: { status: 'active' },
                    include: { account: true },
                    take: 1,
                },
            },
        });
        let supplierAccountId;
        let supplierAccountCode;
        let supplierName;
        if (existingSupplier && existingSupplier.user_accounts.length > 0) {
            supplierAccountId = existingSupplier.user_accounts[0].account_id;
            supplierAccountCode = existingSupplier.user_accounts[0].account.code || '';
            supplierName = existingSupplier.name;
        }
        else {
            const userCode = `U_${(0, crypto_1.randomBytes)(3).toString('hex').toUpperCase()}`;
            const accountCode = `A_${(0, crypto_1.randomBytes)(3).toString('hex').toUpperCase()}`;
            const walletCode = `W_${(0, crypto_1.randomBytes)(3).toString('hex').toUpperCase()}`;
            const token = (0, crypto_1.randomBytes)(32).toString('hex');
            const passwordHash = await bcrypt.hash('default123', 10);
            const newUser = await this.prisma.user.create({
                data: {
                    code: userCode,
                    name,
                    phone: normalizedPhone,
                    email: email?.toLowerCase(),
                    nid,
                    address,
                    password_hash: passwordHash,
                    token,
                    status: 'active',
                    account_type: 'supplier',
                    created_by: user.id,
                },
            });
            const newAccount = await this.prisma.account.create({
                data: {
                    code: accountCode,
                    name,
                    type: 'tenant',
                    status: 'active',
                    created_by: user.id,
                },
            });
            await this.prisma.userAccount.create({
                data: {
                    user_id: newUser.id,
                    account_id: newAccount.id,
                    role: 'supplier',
                    status: 'active',
                    created_by: user.id,
                },
            });
            await this.prisma.wallet.create({
                data: {
                    code: walletCode,
                    account_id: newAccount.id,
                    type: 'regular',
                    is_default: true,
                    balance: 0,
                    currency: 'RWF',
                    status: 'active',
                    created_by: user.id,
                },
            });
            supplierAccountId = newAccount.id;
            supplierAccountCode = accountCode;
            supplierName = name;
        }
        const existingRelationship = await this.prisma.supplierCustomer.findFirst({
            where: {
                supplier_account_id: supplierAccountId,
                customer_account_id: customerAccountId,
            },
        });
        if (existingRelationship) {
            await this.prisma.supplierCustomer.update({
                where: { id: existingRelationship.id },
                data: {
                    price_per_liter: price_per_liter,
                    relationship_status: 'active',
                    updated_by: user.id,
                },
            });
        }
        else {
            await this.prisma.supplierCustomer.create({
                data: {
                    supplier_account_id: supplierAccountId,
                    customer_account_id: customerAccountId,
                    price_per_liter: price_per_liter,
                    relationship_status: 'active',
                    created_by: user.id,
                },
            });
        }
        return {
            code: 200,
            status: 'success',
            message: 'Supplier created/updated successfully.',
            data: {
                supplier: {
                    account_id: supplierAccountId,
                    account_code: supplierAccountCode,
                    name: supplierName,
                    phone: normalizedPhone,
                    price_per_liter: price_per_liter,
                },
            },
        };
    }
};
exports.SuppliersService = SuppliersService;
exports.SuppliersService = SuppliersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SuppliersService);
//# sourceMappingURL=suppliers.service.js.map