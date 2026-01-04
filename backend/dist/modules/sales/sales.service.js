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
exports.SalesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let SalesService = class SalesService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getSales(user, filters) {
        if (!user.default_account_id) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No valid default account found. Please set a default account.',
            });
        }
        const supplierAccountId = user.default_account_id;
        const where = {
            supplier_account_id: supplierAccountId,
            status: { not: 'deleted' },
        };
        if (filters) {
            if (filters.customer_account_code) {
                const customerAccount = await this.prisma.account.findUnique({
                    where: { code: filters.customer_account_code },
                });
                if (customerAccount) {
                    where.customer_account_id = customerAccount.id;
                }
            }
            if (filters.status) {
                where.status = filters.status;
            }
            if (filters.date_from || filters.date_to) {
                where.sale_at = {};
                if (filters.date_from) {
                    where.sale_at.gte = new Date(filters.date_from);
                }
                if (filters.date_to) {
                    const dateTo = new Date(filters.date_to);
                    dateTo.setHours(23, 59, 59, 999);
                    where.sale_at.lte = dateTo;
                }
            }
            if (filters.quantity_min !== undefined || filters.quantity_max !== undefined) {
                where.quantity = {};
                if (filters.quantity_min !== undefined) {
                    where.quantity.gte = filters.quantity_min;
                }
                if (filters.quantity_max !== undefined) {
                    where.quantity.lte = filters.quantity_max;
                }
            }
            if (filters.price_min !== undefined || filters.price_max !== undefined) {
                where.unit_price = {};
                if (filters.price_min !== undefined) {
                    where.unit_price.gte = filters.price_min;
                }
                if (filters.price_max !== undefined) {
                    where.unit_price.lte = filters.price_max;
                }
            }
        }
        const sales = await this.prisma.milkSale.findMany({
            where,
            include: {
                supplier_account: true,
                customer_account: true,
            },
            orderBy: {
                sale_at: 'desc',
            },
        });
        const formattedSales = sales.map((sale) => ({
            id: sale.id,
            quantity: Number(sale.quantity),
            unit_price: Number(sale.unit_price),
            total_amount: Number(sale.quantity) * Number(sale.unit_price),
            status: sale.status,
            sale_at: sale.sale_at,
            notes: sale.notes,
            created_at: sale.created_at,
            supplier_account: {
                code: sale.supplier_account.code,
                name: sale.supplier_account.name,
                type: sale.supplier_account.type,
                status: sale.supplier_account.status,
            },
            customer_account: {
                code: sale.customer_account.code,
                name: sale.customer_account.name,
                type: sale.customer_account.type,
                status: sale.customer_account.status,
            },
        }));
        return {
            code: 200,
            status: 'success',
            message: 'Sales fetched successfully.',
            data: formattedSales,
        };
    }
    async updateSale(user, saleId, updateDto) {
        if (!user.default_account_id) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No valid default account found. Please set a default account.',
            });
        }
        const sale = await this.prisma.milkSale.findFirst({
            where: {
                id: saleId,
                supplier_account_id: user.default_account_id,
            },
        });
        if (!sale) {
            throw new common_1.NotFoundException({
                code: 404,
                status: 'error',
                message: 'Sale not found or not owned by this supplier.',
            });
        }
        const updateData = {
            updated_by: user.id,
        };
        if (updateDto.customer_account_code) {
            const customerAccount = await this.prisma.account.findUnique({
                where: { code: updateDto.customer_account_code },
            });
            if (customerAccount) {
                updateData.customer_account_id = customerAccount.id;
            }
        }
        if (updateDto.quantity !== undefined) {
            updateData.quantity = updateDto.quantity;
        }
        if (updateDto.status) {
            updateData.status = updateDto.status;
        }
        if (updateDto.sale_at) {
            updateData.sale_at = new Date(updateDto.sale_at);
        }
        if (updateDto.notes !== undefined) {
            updateData.notes = updateDto.notes;
        }
        if (Object.keys(updateData).length === 1) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No fields to update.',
            });
        }
        const updatedSale = await this.prisma.milkSale.update({
            where: { id: saleId },
            data: updateData,
            include: {
                supplier_account: true,
                customer_account: true,
            },
        });
        return {
            code: 200,
            status: 'success',
            message: 'Sale updated successfully.',
            data: {
                id: updatedSale.id,
                quantity: Number(updatedSale.quantity),
                unit_price: Number(updatedSale.unit_price),
                status: updatedSale.status,
                sale_at: updatedSale.sale_at,
                notes: updatedSale.notes,
            },
        };
    }
    async cancelSale(user, cancelDto) {
        if (!user.default_account_id) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'No valid default account found. Please set a default account.',
            });
        }
        const sale = await this.prisma.milkSale.findFirst({
            where: {
                id: cancelDto.sale_id,
                supplier_account_id: user.default_account_id,
            },
        });
        if (!sale) {
            throw new common_1.NotFoundException({
                code: 404,
                status: 'error',
                message: 'Sale not found or not authorized.',
            });
        }
        await this.prisma.milkSale.update({
            where: { id: cancelDto.sale_id },
            data: {
                status: 'cancelled',
                updated_by: user.id,
            },
        });
        return {
            code: 200,
            status: 'success',
            message: 'Sale cancelled successfully.',
        };
    }
};
exports.SalesService = SalesService;
exports.SalesService = SalesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SalesService);
//# sourceMappingURL=sales.service.js.map