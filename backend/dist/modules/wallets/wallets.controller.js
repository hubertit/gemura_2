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
exports.WalletsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const wallets_service_1 = require("./wallets.service");
const token_guard_1 = require("../../common/guards/token.guard");
const user_decorator_1 = require("../../common/decorators/user.decorator");
let WalletsController = class WalletsController {
    constructor(walletsService) {
        this.walletsService = walletsService;
    }
    async getWallets(user) {
        return this.walletsService.getWallets(user);
    }
};
exports.WalletsController = WalletsController;
__decorate([
    (0, common_1.Get)('get'),
    (0, swagger_1.ApiOperation)({
        summary: 'Get wallets for default account',
        description: 'Retrieve all wallets associated with the user\'s default account, including balance, currency, type, and status information.',
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Wallets fetched successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Wallets fetched successfully.',
            data: [
                {
                    wallet_code: 'W_ABC123',
                    type: 'regular',
                    is_joint: false,
                    is_default: true,
                    balance: 150000.0,
                    currency: 'RWF',
                    status: 'active',
                    account: {
                        code: 'A_XYZ789',
                        name: 'Main Account',
                        type: 'tenant',
                    },
                },
            ],
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'No default account found',
        example: {
            code: 400,
            status: 'error',
            message: 'No valid default account found. Please set a default account.',
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
        description: 'No wallets found for the account',
        example: {
            code: 404,
            status: 'error',
            message: 'No wallets found for this account.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], WalletsController.prototype, "getWallets", null);
exports.WalletsController = WalletsController = __decorate([
    (0, swagger_1.ApiTags)('Wallets'),
    (0, common_1.Controller)('wallets'),
    (0, common_1.UseGuards)(token_guard_1.TokenGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [wallets_service_1.WalletsService])
], WalletsController);
//# sourceMappingURL=wallets.controller.js.map