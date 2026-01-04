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
    (0, swagger_1.ApiOperation)({ summary: 'Get sales list with filters' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Sales fetched successfully' }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, get_sales_dto_1.GetSalesDto]),
    __metadata("design:returntype", Promise)
], SalesController.prototype, "getSales", null);
__decorate([
    (0, common_1.Put)('update'),
    (0, swagger_1.ApiOperation)({ summary: 'Update a sale' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Sale updated successfully' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Sale not found' }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_sale_dto_1.UpdateSaleDto]),
    __metadata("design:returntype", Promise)
], SalesController.prototype, "updateSale", null);
__decorate([
    (0, common_1.Post)('cancel'),
    (0, swagger_1.ApiOperation)({ summary: 'Cancel a sale' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Sale cancelled successfully' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Sale not found' }),
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