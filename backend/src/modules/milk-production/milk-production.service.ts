import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateMilkProductionDto } from './dto/create-milk-production.dto';
import { UpdateMilkProductionDto } from './dto/update-milk-production.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class MilkProductionService {
  constructor(private readonly prisma: PrismaService) {}

  private getAccountId(user: User, accountId?: string): string {
    const id = accountId || user.default_account_id;
    if (!id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }
    return id;
  }

  async create(user: User, dto: CreateMilkProductionDto, accountId?: string) {
    const accId = this.getAccountId(user, accountId);

    if (!dto.animal_id && !dto.farm_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Provide either animal_id or farm_id (or both).',
      });
    }

    let farmId: string | null = dto.farm_id ?? null;

    if (dto.animal_id) {
      const animal = await this.prisma.animal.findFirst({
        where: { id: dto.animal_id, account_id: accId },
      });
      if (!animal) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Animal not found or does not belong to this account.',
        });
      }
      // Use the cow's registered farm for the production record
      farmId = animal.farm_id;
      if (dto.farm_id && animal.farm_id && animal.farm_id !== dto.farm_id) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Animal is assigned to a different farm.',
        });
    }

    if (farmId) {
      const farm = await this.prisma.farm.findFirst({
        where: { id: farmId, account_id: accId },
      });
      if (!farm) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Farm not found or does not belong to this account.',
        });
      }
    }

    const productionDate = new Date(dto.production_date);
    if (isNaN(productionDate.getTime())) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Invalid production_date.',
      });
    }

    const record = await this.prisma.milkProduction.create({
      data: {
        account_id: accId,
        farm_id: farmId,
        animal_id: dto.animal_id || null,
        production_date: productionDate,
        quantity_litres: dto.quantity_litres,
        session: dto.session || null,
        notes: dto.notes || null,
        created_by: user.id,
      },
      include: {
        animal: { select: { id: true, tag_number: true, name: true } },
        farm: { select: { id: true, name: true, code: true } },
      },
    });
    return record;
  }

  async findAll(
    user: User,
    accountId?: string,
    filters?: { animal_id?: string; farm_id?: string; session?: string; from?: string; to?: string },
  ) {
    const accId = this.getAccountId(user, accountId);
    const where: Prisma.MilkProductionWhereInput = { account_id: accId };

    if (filters?.animal_id) where.animal_id = filters.animal_id;
    if (filters?.farm_id) where.farm_id = filters.farm_id;
    if (filters?.session) where.session = filters.session;
    if (filters?.from || filters?.to) {
      where.production_date = {};
      if (filters.from) (where.production_date as Prisma.DateTimeFilter).gte = new Date(filters.from);
      if (filters.to) (where.production_date as Prisma.DateTimeFilter).lte = new Date(filters.to);
    }

    const list = await this.prisma.milkProduction.findMany({
      where,
      include: {
        animal: { select: { id: true, tag_number: true, name: true } },
        farm: { select: { id: true, name: true, code: true } },
      },
      orderBy: [{ production_date: 'desc' }, { created_at: 'desc' }],
    });
    return list;
  }

  async findOne(user: User, id: string, accountId?: string) {
    const accId = this.getAccountId(user, accountId);
    const record = await this.prisma.milkProduction.findFirst({
      where: { id, account_id: accId },
      include: {
        animal: { select: { id: true, tag_number: true, name: true, breed: { select: { id: true, name: true } } } },
        farm: { select: { id: true, name: true, code: true } },
      },
    });
    if (!record) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Milk production record not found',
      });
    }
    return record;
  }

  async update(
    user: User,
    id: string,
    dto: UpdateMilkProductionDto,
    accountId?: string,
  ) {
    const accId = this.getAccountId(user, accountId);
    const existing = await this.prisma.milkProduction.findFirst({
      where: { id, account_id: accId },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Milk production record not found',
      });
    }

    const data: Prisma.MilkProductionUncheckedUpdateInput = {};
    if (dto.farm_id !== undefined) data.farm_id = dto.farm_id || null;
    if (dto.animal_id !== undefined) data.animal_id = dto.animal_id || null;
    if (dto.production_date !== undefined) data.production_date = new Date(dto.production_date);
    if (dto.quantity_litres !== undefined) data.quantity_litres = dto.quantity_litres;
    if (dto.session !== undefined) data.session = dto.session || null;
    if (dto.notes !== undefined) data.notes = dto.notes || null;

    const updated = await this.prisma.milkProduction.update({
      where: { id },
      data,
      include: {
        animal: { select: { id: true, tag_number: true, name: true } },
        farm: { select: { id: true, name: true, code: true } },
      },
    });
    return updated;
  }

  async remove(user: User, id: string, accountId?: string) {
    const accId = this.getAccountId(user, accountId);
    const existing = await this.prisma.milkProduction.findFirst({
      where: { id, account_id: accId },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Milk production record not found',
      });
    }
    await this.prisma.milkProduction.delete({ where: { id } });
    return { id, message: 'Milk production record deleted' };
  }

  async reportProductionVsSold(
    user: User,
    accountId?: string,
    from?: string,
    to?: string,
  ) {
    const accId = this.getAccountId(user, accountId);
    const fromDate = from ? new Date(from) : undefined;
    const toDate = to ? new Date(to) : undefined;

    const productionWhere: Prisma.MilkProductionWhereInput = { account_id: accId };
    if (fromDate || toDate) {
      productionWhere.production_date = {};
      if (fromDate) (productionWhere.production_date as Prisma.DateTimeFilter).gte = fromDate;
      if (toDate) (productionWhere.production_date as Prisma.DateTimeFilter).lte = toDate;
    }

    const [productionRecords, salesRecords] = await Promise.all([
      this.prisma.milkProduction.aggregate({
        where: productionWhere,
        _sum: { quantity_litres: true },
        _count: true,
      }),
      this.prisma.milkSale.findMany({
        where: {
          supplier_account_id: accId,
          ...(fromDate || toDate
            ? {
                sale_at: {
                  ...(fromDate && { gte: fromDate }),
                  ...(toDate && { lte: toDate }),
                },
              }
            : {}),
        },
        select: { quantity: true, animal_id: true },
      }),
    ]);

    const totalSold = salesRecords.reduce((s, r) => s + Number(r.quantity), 0);
    const totalProduction = Number(productionRecords._sum.quantity_litres ?? 0);

    return {
      from: from ?? null,
      to: to ?? null,
      total_production_litres: totalProduction,
      total_sold_litres: totalSold,
      production_record_count: productionRecords._count,
      sale_count: salesRecords.length,
    };
  }
}
