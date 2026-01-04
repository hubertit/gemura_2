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
exports.CollectionsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let CollectionsService = class CollectionsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createCollection(user, createDto) {
        const { supplier_account_code, quantity, status, collection_at, notes } = createDto;
        if (!user.default_account_id) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No valid default account found. Please set a default account.',
            });
        }
        const customerAccountId = user.default_account_id;
        const supplierAccount = await this.prisma.account.findUnique({
            where: { code: supplier_account_code },
        });
        if (!supplierAccount || supplierAccount.status !== 'active') {
            throw new common_1.NotFoundException({
                code: 404,
                status: 'error',
                message: 'Supplier account not found.',
            });
        }
        const supplierAccountId = supplierAccount.id;
        const relationship = await this.prisma.supplierCustomer.findFirst({
            where: {
                supplier_account_id: supplierAccountId,
                customer_account_id: customerAccountId,
                relationship_status: 'active',
            },
        });
        const unitPrice = relationship?.price_per_liter || 0;
        try {
            const milkSale = await this.prisma.milkSale.create({
                data: {
                    supplier_account_id: supplierAccountId,
                    customer_account_id: customerAccountId,
                    quantity: quantity,
                    unit_price: unitPrice,
                    status: status,
                    sale_at: new Date(collection_at),
                    notes: notes || null,
                    recorded_by: user.id,
                    created_by: user.id,
                },
            });
            return {
                code: 200,
                status: 'success',
                message: 'Milk collection recorded successfully.',
                data: {
                    collection_id: milkSale.id,
                    supplier_account_code: supplier_account_code,
                    customer_account_id: customerAccountId,
                    quantity: quantity,
                    unit_price: unitPrice,
                    total_amount: quantity * Number(unitPrice),
                    status: status,
                    collection_at: collection_at,
                },
            };
        }
        catch (error) {
            throw new common_1.InternalServerErrorException({
                code: 500,
                status: 'error',
                message: 'Failed to record milk collection.',
                error: error.message,
            });
        }
    }
};
exports.CollectionsService = CollectionsService;
exports.CollectionsService = CollectionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CollectionsService);
//# sourceMappingURL=collections.service.js.map