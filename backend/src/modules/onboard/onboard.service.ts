import { Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateUserDto } from './dto/create-user.dto';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';

@Injectable()
export class OnboardService {
  constructor(private prisma: PrismaService) {}

  async createUser(onboarder: User, createUserDto: CreateUserDto) {
    // Normalize phone number (remove spaces, ensure + prefix)
    const normalizedPhone = createUserDto.phone_number.replace(/\s/g, '');

    // Check if phone number already exists
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { phone: normalizedPhone },
          { phone: normalizedPhone.replace(/^\+/, '') }, // Check without +
          { phone: `+${normalizedPhone}` }, // Check with +
        ],
      },
    });

    if (existingUser) {
      throw new ConflictException({
        code: 400,
        status: 'error',
        message: 'Phone number already exists.',
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(createUserDto.password, 10);

    // Generate unique token
    const token = crypto.randomBytes(32).toString('hex');

    // Start transaction
    return await this.prisma.$transaction(async (tx) => {
      // Create new user
      const newUser = await tx.user.create({
        data: {
          name: createUserDto.name,
          phone: normalizedPhone,
          email: createUserDto.email,
          address: createUserDto.location,
          password_hash: passwordHash,
          onboarded_by: parseInt(onboarder.legacy_id?.toString() || '0'),
          registration_type: 'onboarded',
          status: 'active',
          token: token,
          created_by: onboarder.id,
        },
      });

      // Create onboarding record
      // Note: UserOnboarding schema uses user_id, step, completed
      // We'll use step to track the onboarder
      await tx.userOnboarding.create({
        data: {
          user_id: newUser.id,
          step: `onboarded`,
          completed: true,
        },
      });

      // Award points to onboarder
      await tx.userPoint.create({
        data: {
          user_id: onboarder.id,
          points: 1,
          reason: `onboarding:${newUser.id}`,
        },
      });

      // Update onboarder's stats
      await tx.user.update({
        where: { id: onboarder.id },
        data: {
          onboarded_count: { increment: 1 },
          total_points: { increment: 1 },
          available_points: { increment: 1 },
        },
      });

      return {
        code: 201,
        status: 'success',
        message: 'User onboarded successfully.',
        data: {
          onboarded_user: {
            id: newUser.id,
            name: newUser.name,
            phone_number: newUser.phone,
            email: newUser.email,
            location: newUser.address,
            token: newUser.token,
            created_at: newUser.created_at,
          },
          onboarder: {
            name: onboarder.name,
            points_earned: 1,
          },
          onboarded_at: newUser.created_at,
        },
      };
    });
  }
}
