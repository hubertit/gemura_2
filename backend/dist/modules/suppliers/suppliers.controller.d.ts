import { SuppliersService } from './suppliers.service';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';
export declare class SuppliersController {
    private readonly suppliersService;
    constructor(suppliersService: SuppliersService);
    createSupplier(user: User, createDto: CreateSupplierDto): Promise<{
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
