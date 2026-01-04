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
exports.SuppliersController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const suppliers_service_1 = require("./suppliers.service");
const token_guard_1 = require("../../common/guards/token.guard");
const user_decorator_1 = require("../../common/decorators/user.decorator");
const create_supplier_dto_1 = require("./dto/create-supplier.dto");
let SuppliersController = class SuppliersController {
    constructor(suppliersService) {
        this.suppliersService = suppliersService;
    }
    async createSupplier(user, createDto) {
        return this.suppliersService.createOrUpdateSupplier(user, createDto);
    }
};
exports.SuppliersController = SuppliersController;
__decorate([
    (0, common_1.Post)('create'),
    (0, swagger_1.ApiOperation)({
        summary: 'Create or update supplier',
        description: 'Create a new supplier relationship or update an existing one. If supplier exists (by phone/email/nid), updates the relationship. Otherwise, creates new user, account, and wallet.',
    }),
    (0, swagger_1.ApiBody)({
        type: create_supplier_dto_1.CreateSupplierDto,
        description: 'Supplier information',
        examples: {
            createSupplier: {
                summary: 'Create new supplier',
                value: {
                    name: 'John Doe',
                    phone: '250788123456',
                    price_per_liter: 390.0,
                    email: 'supplier@example.com',
                    nid: '1199887766554433',
                    address: 'Kigali, Rwanda',
                },
            },
            minimalSupplier: {
                summary: 'Create supplier with minimal info',
                value: {
                    name: 'Jane Smith',
                    phone: '250788654321',
                    price_per_liter: 400.0,
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Supplier created/updated successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Supplier created/updated successfully.',
            data: {
                supplier: {
                    account_id: 'account-uuid',
                    account_code: 'A_ABC123',
                    name: 'John Doe',
                    phone: '250788123456',
                    price_per_liter: 390.0,
                },
            },
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'Invalid request - missing required fields or no default account',
        examples: {
            missingFields: {
                summary: 'Missing required fields',
                value: {
                    code: 400,
                    status: 'error',
                    message: 'Missing required fields.',
                },
            },
            noDefaultAccount: {
                summary: 'No default account',
                value: {
                    code: 400,
                    status: 'error',
                    message: 'No valid default account found. Please set a default account.',
                },
            },
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
        example: {
            code: 401,
            status: 'error',
            message: 'Unauthorized. Invalid token.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_supplier_dto_1.CreateSupplierDto]),
    __metadata("design:returntype", Promise)
], SuppliersController.prototype, "createSupplier", null);
exports.SuppliersController = SuppliersController = __decorate([
    (0, swagger_1.ApiTags)('Suppliers'),
    (0, common_1.Controller)('suppliers'),
    (0, common_1.UseGuards)(token_guard_1.TokenGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [suppliers_service_1.SuppliersService])
], SuppliersController);
//# sourceMappingURL=suppliers.controller.js.map