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
exports.SalesController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const sales_service_1 = require("./sales.service");
const token_guard_1 = require("../../common/guards/token.guard");
const user_decorator_1 = require("../../common/decorators/user.decorator");
const get_sales_dto_1 = require("./dto/get-sales.dto");
const update_sale_dto_1 = require("./dto/update-sale.dto");
const cancel_sale_dto_1 = require("./dto/cancel-sale.dto");
let SalesController = class SalesController {
    constructor(salesService) {
        this.salesService = salesService;
    }
    async getSales(user, getSalesDto) {
        return this.salesService.getSales(user, getSalesDto.filters);
    }
    async updateSale(user, updateDto) {
        return this.salesService.updateSale(user, updateDto.sale_id, updateDto);
    }
    async cancelSale(user, cancelDto) {
        return this.salesService.cancelSale(user, cancelDto);
    }
};
exports.SalesController = SalesController;
__decorate([
    (0, common_1.Post)('sales'),
    (0, swagger_1.ApiOperation)({
        summary: 'Get sales list with filters',
        description: 'Retrieve sales/milk collections for the authenticated user\'s default account. Supports filtering by customer, status, date range, quantity, and price.',
    }),
    (0, swagger_1.ApiBody)({
        type: get_sales_dto_1.GetSalesDto,
        description: 'Optional filters for sales query',
        examples: {
            allSales: {
                summary: 'Get all sales',
                value: {
                    filters: {},
                },
            },
            filteredSales: {
                summary: 'Get filtered sales',
                value: {
                    filters: {
                        status: 'completed',
                        date_from: '2025-01-01',
                        date_to: '2025-01-31',
                        quantity_min: 50,
                        price_min: 350,
                    },
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Sales fetched successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Sales fetched successfully.',
            data: [
                {
                    id: 'sale-uuid',
                    quantity: 120.5,
                    unit_price: 390.0,
                    total_amount: 46995.0,
                    status: 'completed',
                    sale_at: '2025-01-04T10:00:00Z',
                    supplier_account: {
                        code: 'A_ABC123',
                        name: 'Supplier Name',
                        type: 'tenant',
                        status: 'active',
                    },
                    customer_account: {
                        code: 'A_XYZ789',
                        name: 'Customer Name',
                        type: 'tenant',
                        status: 'active',
                    },
                },
            ],
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'No default account found',
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, get_sales_dto_1.GetSalesDto]),
    __metadata("design:returntype", Promise)
], SalesController.prototype, "getSales", null);
__decorate([
    (0, common_1.Put)('update'),
    (0, swagger_1.ApiOperation)({
        summary: 'Update a sale',
        description: 'Update sale details including quantity, status, customer, notes, or date. Only sales belonging to the user\'s default account can be updated.',
    }),
    (0, swagger_1.ApiBody)({
        type: update_sale_dto_1.UpdateSaleDto,
        description: 'Sale update data',
        examples: {
            updateStatus: {
                summary: 'Update sale status',
                value: {
                    sale_id: 'sale-uuid',
                    status: 'completed',
                },
            },
            updateQuantity: {
                summary: 'Update quantity and notes',
                value: {
                    sale_id: 'sale-uuid',
                    quantity: 150.0,
                    notes: 'Updated quantity after verification',
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Sale updated successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Sale updated successfully.',
            data: {
                id: 'sale-uuid',
                quantity: 150.0,
                unit_price: 390.0,
                status: 'completed',
                sale_at: '2025-01-04T10:00:00Z',
                notes: 'Updated quantity',
            },
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'Invalid request - no fields to update or missing sale_id',
        example: {
            code: 400,
            status: 'error',
            message: 'No fields to update.',
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
    }),
    (0, swagger_1.ApiNotFoundResponse)({
        description: 'Sale not found or not owned by user',
        example: {
            code: 404,
            status: 'error',
            message: 'Sale not found or not owned by this supplier.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_sale_dto_1.UpdateSaleDto]),
    __metadata("design:returntype", Promise)
], SalesController.prototype, "updateSale", null);
__decorate([
    (0, common_1.Post)('cancel'),
    (0, swagger_1.ApiOperation)({
        summary: 'Cancel a sale',
        description: 'Cancel a sale by setting its status to "cancelled". Only sales belonging to the user\'s default account can be cancelled.',
    }),
    (0, swagger_1.ApiBody)({
        type: cancel_sale_dto_1.CancelSaleDto,
        description: 'Sale ID to cancel',
        examples: {
            cancelSale: {
                summary: 'Cancel sale',
                value: {
                    sale_id: 'sale-uuid',
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Sale cancelled successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Sale cancelled successfully.',
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'Invalid request - missing sale_id',
        example: {
            code: 400,
            status: 'error',
            message: 'Missing token or sale_id.',
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
    }),
    (0, swagger_1.ApiNotFoundResponse)({
        description: 'Sale not found or not authorized',
        example: {
            code: 404,
            status: 'error',
            message: 'Sale not found or not authorized.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, cancel_sale_dto_1.CancelSaleDto]),
    __metadata("design:returntype", Promise)
], SalesController.prototype, "cancelSale", null);
exports.SalesController = SalesController = __decorate([
    (0, swagger_1.ApiTags)('Sales'),
    (0, common_1.Controller)('sales'),
    (0, common_1.UseGuards)(token_guard_1.TokenGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [sales_service_1.SalesService])
], SalesController);
//# sourceMappingURL=sales.controller.js.map