import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';
export declare class SuppliersService {
    private prisma;
    constructor(prisma: PrismaService);
    createOrUpdateSupplier(user: User, createDto: CreateSupplierDto): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            supplier: {
                account_id: string;
                account_code: string;
                name: string;
                phone: string;
                price_per_liter: number;
            };
        };
    }>;
}
