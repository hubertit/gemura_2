import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { SalesFiltersDto } from './dto/get-sales.dto';
import { UpdateSaleDto } from './dto/update-sale.dto';
import { CancelSaleDto } from './dto/cancel-sale.dto';
export declare class SalesService {
    private prisma;
    constructor(prisma: PrismaService);
    getSales(user: User, filters?: SalesFiltersDto): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            id: string;
            quantity: number;
            unit_price: number;
            total_amount: number;
            status: import(".prisma/client").$Enums.MilkSaleStatus;
            sale_at: Date;
            notes: string;
            created_at: Date;
            supplier_account: {
                code: string;
                name: string;
                type: import(".prisma/client").$Enums.AccountType;
                status: import(".prisma/client").$Enums.AccountStatus;
            };
            customer_account: {
                code: string;
                name: string;
                type: import(".prisma/client").$Enums.AccountType;
                status: import(".prisma/client").$Enums.AccountStatus;
            };
        }[];
    }>;
    updateSale(user: User, saleId: string, updateDto: UpdateSaleDto): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            id: string;
            quantity: number;
            unit_price: number;
            status: import(".prisma/client").$Enums.MilkSaleStatus;
            sale_at: Date;
            notes: string;
        };
    }>;
    cancelSale(user: User, cancelDto: CancelSaleDto): Promise<{
        code: number;
        status: string;
        message: string;
    }>;
}
