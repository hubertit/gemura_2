import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';
export declare class CollectionsService {
    private prisma;
    constructor(prisma: PrismaService);
    createCollection(user: User, createDto: CreateCollectionDto): Promise<{
        code: number;
        status: string;
        message: string;
        data: {
            collection_id: string;
            supplier_account_code: string;
            customer_account_id: string;
            quantity: number;
            unit_price: number | import("@prisma/client/runtime/library").Decimal;
            total_amount: number;
            status: string;
            collection_at: string;
        };
    }>;
}
