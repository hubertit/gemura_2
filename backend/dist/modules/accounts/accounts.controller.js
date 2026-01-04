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
exports.AccountsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const accounts_service_1 = require("./accounts.service");
const token_guard_1 = require("../../common/guards/token.guard");
const user_decorator_1 = require("../../common/decorators/user.decorator");
const switch_account_dto_1 = require("./dto/switch-account.dto");
let AccountsController = class AccountsController {
    constructor(accountsService) {
        this.accountsService = accountsService;
    }
    async getAccounts(user) {
        return this.accountsService.getUserAccounts(user);
    }
    async listAccounts(user) {
        return this.accountsService.getUserAccounts(user);
    }
    async switchAccount(user, switchDto) {
        return this.accountsService.switchAccount(user, switchDto);
    }
};
exports.AccountsController = AccountsController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({
        summary: 'Get user accounts',
        description: 'Retrieve all accounts that the authenticated user has access to, including roles, permissions, and default account information.',
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'User accounts fetched successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'User accounts fetched successfully.',
            data: {
                user: {
                    id: 'uuid-here',
                    name: 'John Doe',
                    email: 'user@example.com',
                    phone: '250788123456',
                    default_account_id: 'account-uuid',
                },
                accounts: [
                    {
                        account_id: 'account-uuid',
                        account_code: 'ACC001',
                        account_name: 'Main Account',
                        account_type: 'tenant',
                        account_status: 'active',
                        role: 'owner',
                        permissions: { can_manage: true },
                        is_default: true,
                    },
                ],
                total_accounts: 1,
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
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AccountsController.prototype, "getAccounts", null);
__decorate([
    (0, common_1.Get)('list'),
    (0, swagger_1.ApiOperation)({
        summary: 'List user accounts',
        description: 'Alias endpoint for GET /accounts. Returns the same data structure.',
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'User accounts fetched successfully',
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AccountsController.prototype, "listAccounts", null);
__decorate([
    (0, common_1.Post)('switch'),
    (0, swagger_1.ApiOperation)({
        summary: 'Switch default account',
        description: 'Change the user\'s default account. The default account is used for operations when no specific account is specified.',
    }),
    (0, swagger_1.ApiBody)({
        type: switch_account_dto_1.SwitchAccountDto,
        description: 'Account ID to switch to',
        examples: {
            switchAccount: {
                summary: 'Switch to account',
                value: {
                    account_id: '550e8400-e29b-41d4-a716-446655440000',
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Default account switched successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Default account switched successfully.',
            data: {
                user: {
                    id: 'uuid-here',
                    name: 'John Doe',
                    default_account_id: 'account-uuid',
                },
                account: {
                    id: 'account-uuid',
                    code: 'ACC001',
                    name: 'Main Account',
                    type: 'tenant',
                },
            },
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'Invalid request - missing account_id',
        example: {
            code: 400,
            status: 'error',
            message: 'Token and account_id are required.',
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
    (0, swagger_1.ApiForbiddenResponse)({
        description: 'User does not have access to the specified account',
        example: {
            code: 403,
            status: 'error',
            message: 'Access denied. You don\'t have permission to access this account.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, switch_account_dto_1.SwitchAccountDto]),
    __metadata("design:returntype", Promise)
], AccountsController.prototype, "switchAccount", null);
exports.AccountsController = AccountsController = __decorate([
    (0, swagger_1.ApiTags)('Accounts'),
    (0, common_1.Controller)('accounts'),
    (0, common_1.UseGuards)(token_guard_1.TokenGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [accounts_service_1.AccountsService])
], AccountsController);
//# sourceMappingURL=accounts.controller.js.map