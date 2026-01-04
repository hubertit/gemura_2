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
exports.CollectionsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const collections_service_1 = require("./collections.service");
const token_guard_1 = require("../../common/guards/token.guard");
const user_decorator_1 = require("../../common/decorators/user.decorator");
const create_collection_dto_1 = require("./dto/create-collection.dto");
let CollectionsController = class CollectionsController {
    constructor(collectionsService) {
        this.collectionsService = collectionsService;
    }
    async createCollection(user, createDto) {
        return this.collectionsService.createCollection(user, createDto);
    }
};
exports.CollectionsController = CollectionsController;
__decorate([
    (0, common_1.Post)('create'),
    (0, swagger_1.ApiOperation)({
        summary: 'Record milk collection',
        description: 'Record a milk collection transaction from a supplier. The collection is stored as a milk sale record with quantity, unit price, and status.',
    }),
    (0, swagger_1.ApiBody)({
        type: create_collection_dto_1.CreateCollectionDto,
        description: 'Milk collection details',
        examples: {
            pendingCollection: {
                summary: 'Record pending collection',
                value: {
                    supplier_account_code: 'A_ABC123',
                    quantity: 120.5,
                    status: 'pending',
                    collection_at: '2025-01-04 10:00:00',
                    notes: 'Morning collection',
                },
            },
            completedCollection: {
                summary: 'Record completed collection',
                value: {
                    supplier_account_code: 'A_XYZ789',
                    quantity: 85.0,
                    status: 'completed',
                    collection_at: '2025-01-04 14:30:00',
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Milk collection recorded successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Milk collection recorded successfully.',
            data: {
                collection_id: 'uuid-here',
                supplier_account_code: 'A_ABC123',
                customer_account_id: 'account-uuid',
                quantity: 120.5,
                unit_price: 390.0,
                total_amount: 46995.0,
                status: 'pending',
                collection_at: '2025-01-04 10:00:00',
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
            message: 'Access denied. Token is required.',
        },
    }),
    (0, swagger_1.ApiNotFoundResponse)({
        description: 'Supplier account not found',
        example: {
            code: 404,
            status: 'error',
            message: 'Supplier account not found.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_collection_dto_1.CreateCollectionDto]),
    __metadata("design:returntype", Promise)
], CollectionsController.prototype, "createCollection", null);
exports.CollectionsController = CollectionsController = __decorate([
    (0, swagger_1.ApiTags)('Collections'),
    (0, common_1.Controller)('collections'),
    (0, common_1.UseGuards)(token_guard_1.TokenGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [collections_service_1.CollectionsService])
], CollectionsController);
//# sourceMappingURL=collections.controller.js.map