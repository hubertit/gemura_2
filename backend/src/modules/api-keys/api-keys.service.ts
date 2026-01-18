import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateApiKeyDto } from './dto/create-api-key.dto';
import * as crypto from 'crypto';

@Injectable()
export class ApiKeysService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createApiKeyDto: CreateApiKeyDto) {
    // Generate API key
    const apiKey = this.generateApiKey();

    // Set expiration date (default 1 year)
    const expiresAt = new Date();
    expiresAt.setFullYear(expiresAt.getFullYear() + 1);

    const apiKeyRecord = await this.prisma.apiKey.create({
      data: {
        key: apiKey, // Store the key directly (in production, you'd hash it)
        name: createApiKeyDto.name,
        expires_at: createApiKeyDto.expires_at ? new Date(createApiKeyDto.expires_at) : expiresAt,
        is_active: true,
      },
    });

    // Return the API key (only shown once on creation)
    return {
      ...apiKeyRecord,
      api_key: apiKey, // Return the key for user to save
    };
  }

  async findAll(userId: string) {
    return this.prisma.apiKey.findMany({
      orderBy: { created_at: 'desc' },
      select: {
        id: true,
        name: true,
        expires_at: true,
        is_active: true,
        created_at: true,
        updated_at: true,
        // Don't return the actual key
      },
    });
  }

  async remove(id: string, userId: string) {
    const apiKey = await this.prisma.apiKey.findUnique({
      where: { id },
    });

    if (!apiKey) {
      throw new Error('API key not found');
    }

    return this.prisma.apiKey.delete({
      where: { id },
    });
  }

  private generateApiKey(): string {
    // Generate a secure random API key
    const prefix = 'gemura_';
    const randomBytes = crypto.randomBytes(32).toString('hex');
    return `${prefix}${randomBytes}`;
  }

  private hashApiKey(apiKey: string): string {
    return crypto.createHash('sha256').update(apiKey).digest('hex');
  }
}

