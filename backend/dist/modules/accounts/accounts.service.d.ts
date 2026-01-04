import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { SwitchAccountDto } from './dto/switch-account.dto';
export declare class AccountsService {
    private prisma;
    constructor(prisma: PrismaService);
    getUserAccounts(user: User): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            user: {
                id: string;
                name: string;
                email: string;
                phone: string;
                default_account_id: string;
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
        };
    }>;
    switchAccount(user: User, switchDto: SwitchAccountDto): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            user: {
                id: string;
                name: string;
                default_account_id: string;
            };
            account: {
                id: string;
                code: string;
                name: string;
                type: import(".prisma/client").$Enums.AccountType;
            };
        };
    }>;
}
