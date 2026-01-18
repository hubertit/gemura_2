import { Injectable, UnauthorizedException, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto, LoginResponseDataDto } from './dto/auth-response.dto';
import { RegisterDto } from './dto/register.dto';
import { VerifyTokenDto } from './dto/verify-token.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {}

  async login(loginDto: LoginDto, ipAddress?: string, userAgent?: string): Promise<AuthResponseDto> {
    const { identifier, password } = loginDto;

    // Determine if identifier is email or phone
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
    const field = isEmail ? 'email' : 'phone';
    const value = isEmail ? identifier.toLowerCase() : identifier.replace(/\D/g, '');

    // Find user (phone numbers should be unique now)
    const user = await this.prisma.user.findFirst({
      where: {
        [field]: value,
        status: 'active',
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
    // Skip PHP bcrypt format ($2y$) as Node.js bcrypt doesn't support it
    if (user.password_hash.startsWith('$2y$')) {
      throw new UnauthorizedException({
        code: 401,
        status: 'error',
        message: 'Invalid credentials.',
      });
    }

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

  async register(registerDto: RegisterDto): Promise<any> {
    const { name, phone, email, password, account_name, account_type, nid, role, permissions, wallet } = registerDto;

    // Normalize phone
    const normalizedPhone = phone.replace(/\D/g, '');
    const normalizedEmail = email ? email.toLowerCase().trim() : null;

    // Check if user exists
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { phone: normalizedPhone },
          ...(nid ? [{ nid }] : []),
        ],
      },
    });

    if (existingUser) {
      throw new ConflictException({
        code: 409,
        status: 'error',
        message: 'Phone number already registered.',
      });
    }

    // Generate codes
    const userCode = `U_${Math.random().toString(36).substring(2, 5).toUpperCase()}`;
    const accountCode = `A_${Math.random().toString(36).substring(2, 5).toUpperCase()}`;
    const walletCode = `W_${Math.random().toString(36).substring(2, 5).toUpperCase()}`;
    const token = `token_${Date.now()}_${Math.random().toString(36).substring(7)}`;

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Default permissions
    const defaultPermissions = {
      can_collect: true,
      can_add_supplier: true,
      can_view_reports: true,
    };
    const userPermissions = permissions || defaultPermissions;

    // Create user, account, wallet in transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Create user
      const user = await tx.user.create({
        data: {
          code: userCode,
          name: name.trim(),
          email: normalizedEmail,
          phone: normalizedPhone,
          nid: nid?.trim() || null,
          password_hash: passwordHash,
          token,
          account_type: account_type || 'mcc',
          status: 'active',
        },
      });

      // Create account
      const account = await tx.account.create({
        data: {
          code: accountCode,
          name: account_name.trim(),
          type: 'tenant',
          status: 'active',
          created_by: user.id,
        },
      });

      // Link user to account
      await tx.userAccount.create({
        data: {
          user_id: user.id,
          account_id: account.id,
          role: role || 'customer',
          permissions: userPermissions,
          status: 'active',
          created_by: user.id,
        },
      });

      // Set default account
      await tx.user.update({
        where: { id: user.id },
        data: { default_account_id: account.id },
      });

      // Create wallet
      const walletData = await tx.wallet.create({
        data: {
          code: walletCode,
          account_id: account.id,
          type: wallet?.type || 'regular',
          is_joint: wallet?.is_joint || false,
          is_default: true,
          balance: 0,
          currency: 'RWF',
          status: 'active',
          created_by: user.id,
        },
      });

      return { user, account, wallet: walletData };
    });

    return {
      code: 201,
      status: 'success',
      message: 'Registration successful.',
      data: {
        user: {
          code: result.user.code,
          name: result.user.name,
          email: result.user.email,
          phone: result.user.phone,
          nid: result.user.nid,
          account_type: result.user.account_type,
          status: result.user.status,
          token: result.user.token,
        },
        account: {
          code: result.account.code,
          name: result.account.name,
          type: result.account.type,
          status: result.account.status,
        },
        wallet: {
          code: result.wallet.code,
          type: result.wallet.type,
          is_joint: result.wallet.is_joint,
          is_default: result.wallet.is_default,
          balance: result.wallet.balance,
          currency: result.wallet.currency,
          status: result.wallet.status,
        },
        sms_sent: false, // TODO: Implement SMS service
      },
    };
  }

  async verifyToken(verifyTokenDto: VerifyTokenDto): Promise<any> {
    const { token } = verifyTokenDto;

    const user = await this.prisma.user.findFirst({
      where: {
        token,
        status: 'active',
      },
      select: {
        code: true,
        name: true,
        email: true,
        phone: true,
        status: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException({
        code: 401,
        status: 'error',
        message: 'Token is invalid or expired.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Token is valid.',
      data: user,
    };
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto): Promise<any> {
    const { phone, email } = forgotPasswordDto;

    if (!phone && !email) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Phone number or email is required.',
      });
    }

    // Find user
    const where: any = {};
    if (phone) {
      where.phone = phone.replace(/\D/g, '');
    }
    if (email) {
      where.email = email.toLowerCase().trim();
    }

    const user = await this.prisma.user.findFirst({
      where: phone && email ? { OR: [{ phone: where.phone }, { email: where.email }] } : where,
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
      },
    });

    if (!user) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'User not found with provided phone or email.',
      });
    }

    // Generate 6-digit reset code
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 15);

    // Store reset code (using token field to store the code)
    await this.prisma.passwordReset.create({
      data: {
        user_id: user.id,
        token: resetCode,
        expires_at: expiresAt,
      },
    });

    // TODO: Send SMS/Email with reset code
    const smsSent = false;
    const emailSent = false;

    return {
      code: 200,
      status: 'success',
      message: 'Reset code sent successfully.',
      data: {
        user_id: parseInt(user.id) || 0, // Legacy compatibility - PHP uses int
        sms_sent: smsSent,
        email_sent: emailSent,
        contact_info: {
          phone: user.phone,
          email: user.email,
        },
      },
    };
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto): Promise<any> {
    const { user_id, reset_code, new_password } = resetPasswordDto;

    // Find user by legacy_id (PHP uses int) or UUID id
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { legacy_id: BigInt(user_id) },
          { id: user_id.toString() },
        ],
      },
    });

    if (!user) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'User not found.',
      });
    }

    // Find valid reset code
    const resetRecord = await this.prisma.passwordReset.findFirst({
      where: {
        user_id: user.id,
        token: reset_code,
        expires_at: { gte: new Date() },
        used_at: null,
      },
    });

    if (!resetRecord) {
      throw new UnauthorizedException({
        code: 401,
        status: 'error',
        message: 'Invalid or expired reset code.',
      });
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(new_password, 10);

    // Update password and mark reset code as used
    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: user.id },
        data: { password_hash: passwordHash },
      });

      await tx.passwordReset.update({
        where: { id: resetRecord.id },
        data: { used_at: new Date() },
      });
    });

    return {
      code: 200,
      status: 'success',
      message: 'Password has been reset successfully.',
    };
  }
}

