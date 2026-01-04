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
exports.ProfileController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const profile_service_1 = require("./profile.service");
const token_guard_1 = require("../../common/guards/token.guard");
const user_decorator_1 = require("../../common/decorators/user.decorator");
const update_profile_dto_1 = require("./dto/update-profile.dto");
let ProfileController = class ProfileController {
    constructor(profileService) {
        this.profileService = profileService;
    }
    async getProfile(user) {
        return this.profileService.getProfile(user);
    }
    async updateProfile(user, updateDto) {
        return this.profileService.updateProfile(user, updateDto);
    }
};
exports.ProfileController = ProfileController;
__decorate([
    (0, common_1.Get)('get'),
    (0, swagger_1.ApiOperation)({
        summary: 'Get user profile',
        description: 'Retrieve the authenticated user\'s profile information including personal details, accounts, and profile completion percentage.',
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Profile retrieved successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Profile retrieved successfully',
            data: {
                user: {
                    id: 'uuid-here',
                    name: 'John Doe',
                    email: 'user@example.com',
                    phone: '250788123456',
                    account_type: 'mcc',
                    status: 'active',
                    token: 'auth-token-here',
                },
                account: {
                    id: 'account-uuid',
                    code: 'ACC001',
                    name: 'Main Account',
                    type: 'tenant',
                },
                accounts: [],
                total_accounts: 1,
                profile_completion: 75,
            },
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
        example: {
            code: 403,
            status: 'error',
            message: 'Unauthorized. Invalid token.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ProfileController.prototype, "getProfile", null);
__decorate([
    (0, common_1.Put)('update'),
    (0, swagger_1.ApiOperation)({
        summary: 'Update user profile',
        description: 'Update user profile information including personal details and KYC information. Uploading KYC photos automatically sets KYC status to pending.',
    }),
    (0, swagger_1.ApiBody)({
        type: update_profile_dto_1.UpdateProfileDto,
        description: 'Profile update data (all fields optional except name and phone)',
        examples: {
            basicUpdate: {
                summary: 'Update basic information',
                value: {
                    name: 'John Doe Updated',
                    phone: '250788123456',
                    email: 'newemail@example.com',
                },
            },
            kycUpdate: {
                summary: 'Update with KYC information',
                value: {
                    name: 'John Doe',
                    phone: '250788123456',
                    province: 'Kigali',
                    district: 'Nyarugenge',
                    sector: 'Nyamirambo',
                    id_number: '1199887766554433',
                    id_front_photo_url: 'https://example.com/id-front.jpg',
                    id_back_photo_url: 'https://example.com/id-back.jpg',
                    selfie_photo_url: 'https://example.com/selfie.jpg',
                },
            },
        },
    }),
    (0, swagger_1.ApiResponse)({
        status: 200,
        description: 'Profile updated successfully',
        example: {
            code: 200,
            status: 'success',
            message: 'Profile retrieved successfully',
            data: {
                user: {
                    id: 'uuid-here',
                    name: 'John Doe Updated',
                    email: 'newemail@example.com',
                    phone: '250788123456',
                    account_type: 'mcc',
                    status: 'active',
                    token: 'auth-token-here',
                },
                accounts: [],
                total_accounts: 1,
                profile_completion: 85,
            },
        },
    }),
    (0, swagger_1.ApiBadRequestResponse)({
        description: 'Invalid request - missing required fields',
        example: {
            code: 400,
            status: 'error',
            message: 'Name and phone are required.',
        },
    }),
    (0, swagger_1.ApiUnauthorizedResponse)({
        description: 'Invalid or missing authentication token',
        example: {
            code: 403,
            status: 'error',
            message: 'Unauthorized. Invalid token.',
        },
    }),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_profile_dto_1.UpdateProfileDto]),
    __metadata("design:returntype", Promise)
], ProfileController.prototype, "updateProfile", null);
exports.ProfileController = ProfileController = __decorate([
    (0, swagger_1.ApiTags)('Profile'),
    (0, common_1.Controller)('profile'),
    (0, common_1.UseGuards)(token_guard_1.TokenGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [profile_service_1.ProfileService])
], ProfileController);
//# sourceMappingURL=profile.controller.js.map