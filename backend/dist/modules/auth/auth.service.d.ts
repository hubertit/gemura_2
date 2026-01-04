import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
export declare class AuthService {
    private prisma;
    constructor(prisma: PrismaService);
    login(loginDto: LoginDto, ipAddress?: string, userAgent?: string): Promise<AuthResponseDto>;
}
