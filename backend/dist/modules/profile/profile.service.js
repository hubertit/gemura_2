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
exports.ProfileService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let ProfileService = class ProfileService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getProfile(user) {
        const userAccounts = await this.prisma.userAccount.findMany({
            where: {
                user_id: user.id,
                status: 'active',
            },
            include: {
                account: true,
            },
            orderBy: {
                created_at: 'desc',
            },
        });
        const accounts = userAccounts
            .filter((ua) => ua.account && ua.account.status === 'active')
            .map((ua) => ({
            account_id: ua.account.id,
            account_code: ua.account.code,
            account_name: ua.account.name,
            account_type: ua.account.type,
            account_status: ua.account.status,
            account_created_at: ua.account.created_at,
            role: ua.role,
            permissions: ua.permissions
                ? typeof ua.permissions === 'string'
                    ? JSON.parse(ua.permissions)
                    : ua.permissions
                : null,
            user_account_status: ua.status,
            access_granted_at: ua.created_at,
            is_default: user.default_account_id === ua.account.id,
        }));
        const defaultAccount = accounts.find((a) => a.is_default);
        const defaultAccountData = defaultAccount
            ? {
                id: defaultAccount.account_id,
                code: defaultAccount.account_code,
                name: defaultAccount.account_name,
                type: defaultAccount.account_type,
            }
            : null;
        const profileFields = [
            'name',
            'email',
            'phone',
            'province',
            'district',
            'sector',
            'cell',
            'village',
            'id_number',
            'id_front_photo_url',
            'id_back_photo_url',
            'selfie_photo_url',
        ];
        let completedFields = 0;
        for (const field of profileFields) {
            if (user[field]) {
                completedFields++;
            }
        }
        const profileCompletion = Math.round((completedFields / profileFields.length) * 100);
        return {
            code: 200,
            status: 'success',
            message: 'Profile retrieved successfully',
            data: {
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    account_type: user.account_type,
                    status: user.status,
                    token: user.token,
                },
                account: defaultAccountData,
                accounts,
                total_accounts: accounts.length,
                profile_completion: profileCompletion,
            },
        };
    }
    async updateProfile(user, updateDto) {
        const updateData = {
            updated_by: user.id,
        };
        if (updateDto.name)
            updateData.name = updateDto.name;
        if (updateDto.email !== undefined)
            updateData.email = updateDto.email || null;
        if (updateDto.phone) {
            updateData.phone = updateDto.phone.replace(/\D/g, '');
        }
        if (updateDto.nid !== undefined)
            updateData.nid = updateDto.nid || null;
        if (updateDto.address !== undefined)
            updateData.address = updateDto.address || null;
        if (updateDto.province !== undefined)
            updateData.province = updateDto.province || null;
        if (updateDto.district !== undefined)
            updateData.district = updateDto.district || null;
        if (updateDto.sector !== undefined)
            updateData.sector = updateDto.sector || null;
        if (updateDto.cell !== undefined)
            updateData.cell = updateDto.cell || null;
        if (updateDto.village !== undefined)
            updateData.village = updateDto.village || null;
        if (updateDto.id_number !== undefined)
            updateData.id_number = updateDto.id_number || null;
        if (updateDto.id_front_photo_url !== undefined)
            updateData.id_front_photo_url = updateDto.id_front_photo_url || null;
        if (updateDto.id_back_photo_url !== undefined)
            updateData.id_back_photo_url = updateDto.id_back_photo_url || null;
        if (updateDto.selfie_photo_url !== undefined)
            updateData.selfie_photo_url = updateDto.selfie_photo_url || null;
        if (updateDto.id_front_photo_url ||
            updateDto.id_back_photo_url ||
            updateDto.selfie_photo_url) {
            updateData.kyc_status = 'pending';
        }
        if (!updateData.name || !updateData.phone) {
            throw new common_1.BadRequestException({
                code: 400,
                status: 'error',
                message: 'Name and phone are required.',
            });
        }
        const updatedUser = await this.prisma.user.update({
            where: { id: user.id },
            data: updateData,
        });
        return this.getProfile(updatedUser);
    }
};
exports.ProfileService = ProfileService;
exports.ProfileService = ProfileService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ProfileService);
//# sourceMappingURL=profile.service.js.map