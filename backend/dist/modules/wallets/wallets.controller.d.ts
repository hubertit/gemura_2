import { WalletsService } from './wallets.service';
import { User } from '@prisma/client';
export declare class WalletsController {
    private readonly walletsService;
    constructor(walletsService: WalletsService);
    getWallets(user: User): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            wallet_code: string;
            type: import(".prisma/client").$Enums.WalletType;
            is_joint: boolean;
            is_default: boolean;
            balance: number;
            currency: string;
            status: import(".prisma/client").$Enums.WalletStatus;
            account: {
                code: string;
                name: string;
                type: import(".prisma/client").$Enums.AccountType;
            };
        }[];
    }>;
}
