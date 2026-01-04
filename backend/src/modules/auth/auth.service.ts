import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto, LoginResponseDataDto } from './dto/auth-response.dto';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {}

  async login(loginDto: LoginDto, ipAddress?: string, userAgent?: string): Promise<AuthResponseDto> {
    const { identifier, password } = loginDto;

    // Determine if identifier is email or phone
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
    const field = isEmail ? 'email' : 'phone';
    const value = isEmail ? identifier.toLowerCase() : identifier.replace(/\D/g, '');

    // Find user
    const user = await this.prisma.user.findFirst({
      where: {
        [field]: value,
      },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 401,
        status: 'error',
        message: 'Invalid credentials.',
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      throw new UnauthorizedException({
        code: 401,
        status: 'error',
        message: 'Invalid credentials.',
      });
    }

    // Get user accounts (same query as PHP)
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

    // Format accounts (matching PHP response structure)
    const accounts = userAccounts
      .filter((ua) => ua.account && ua.account.status === 'active')
      .map((ua) => ({
        account_id: ua.account!.id,
        account_code: ua.account!.code,
        account_name: ua.account!.name,
        account_type: ua.account!.type,
        account_status: ua.account!.status,
        account_created_at: ua.account!.created_at,
        role: ua.role,
        permissions: ua.permissions ? (typeof ua.permissions === 'string' ? JSON.parse(ua.permissions) : ua.permissions) : null,
        user_account_status: ua.status,
        access_granted_at: ua.created_at,
        is_default: user.default_account_id === ua.account!.id,
      }));

    // Find default account
    const defaultAccount = accounts.find((a) => a.is_default);
    const defaultAccountData = defaultAccount
      ? {
          id: defaultAccount.account_id,
          code: defaultAccount.account_code,
          name: defaultAccount.account_name,
          type: defaultAccount.account_type,
        }
      : null;

    // Calculate profile completion (same fields as PHP)
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

    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        last_login: new Date(),
        last_login_ip: ipAddress,
        last_login_device: userAgent,
      },
    });

    // Return response matching PHP format
    return {
      code: 200,
      status: 'success',
      message: 'Login successful.',
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
}

