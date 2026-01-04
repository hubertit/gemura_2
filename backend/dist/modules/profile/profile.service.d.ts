import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { UpdateProfileDto } from './dto/update-profile.dto';
export declare class ProfileService {
    private prisma;
    constructor(prisma: PrismaService);
    getProfile(user: User): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            user: {
                id: string;
                name: string;
                email: string;
                phone: string;
                account_type: import(".prisma/client").$Enums.UserAccountType;
                status: import(".prisma/client").$Enums.UserStatus;
                token: string;
            };
            account: {
                id: string;
                code: string;
                name: string;
                type: import(".prisma/client").$Enums.AccountType;
            };
            accounts: {
                account_id: string;
                account_code: string;
                account_name: string;
                account_type: import(".prisma/client").$Enums.AccountType;
                account_status: import(".prisma/client").$Enums.AccountStatus;
                account_created_at: Date;
                role: import(".prisma/client").$Enums.UserAccountRole;
                permissions: any;
                user_account_status: import(".prisma/client").$Enums.UserAccountStatus;
                access_granted_at: Date;
                is_default: boolean;
            }[];
            total_accounts: number;
            profile_completion: number;
        };
    }>;
    updateProfile(user: User, updateDto: UpdateProfileDto): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            user: {
                id: string;
                name: string;
                email: string;
                phone: string;
                account_type: import(".prisma/client").$Enums.UserAccountType;
                status: import(".prisma/client").$Enums.UserStatus;
                token: string;
            };
            account: {
                id: string;
                code: string;
                name: string;
                type: import(".prisma/client").$Enums.AccountType;
            };
            accounts: {
                account_id: string;
                account_code: string;
                account_name: string;
                account_type: import(".prisma/client").$Enums.AccountType;
                account_status: import(".prisma/client").$Enums.AccountStatus;
                account_created_at: Date;
                role: import(".prisma/client").$Enums.UserAccountRole;
                permissions: any;
                user_account_status: import(".prisma/client").$Enums.UserAccountStatus;
                access_granted_at: Date;
                is_default: boolean;
            }[];
            total_accounts: number;
            profile_completion: number;
        };
    }>;
}
