import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateAnimalDto } from './dto/create-animal.dto';
import { UpdateAnimalDto } from './dto/update-animal.dto';
import { CreateAnimalWeightDto } from './dto/create-animal-weight.dto';
import { CreateAnimalHealthDto } from './dto/create-animal-health.dto';
import { AnimalStatus, Prisma } from '@prisma/client';

export interface AnimalsListFilters {
  status?: AnimalStatus;
  breed?: string;
  gender?: string;
  search?: string;
  farm_id?: string;
}

@Injectable()
export class AnimalsService {
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

  async getAnimals(
    user: User,
    filters?: AnimalsListFilters,
    accountId?: string,
  ) {
    const accId = this.getAccountId(user, accountId);
    const where: Prisma.AnimalWhereInput = { account_id: accId };

    if (filters?.status) where.status = filters.status;
    if (filters?.breed) where.breed = { equals: filters.breed, mode: 'insensitive' };
    if (filters?.gender) where.gender = filters.gender as any;
    if (filters?.farm_id) where.farm_id = filters.farm_id;
    if (filters?.search) {
      where.OR = [
        { tag_number: { contains: filters.search, mode: 'insensitive' } },
        { name: { contains: filters.search, mode: 'insensitive' } },
        { breed: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const animals = await this.prisma.animal.findMany({
      where,
      include: {
        mother: { select: { id: true, tag_number: true, name: true } },
        father: { select: { id: true, tag_number: true, name: true } },
      },
      orderBy: [{ tag_number: 'asc' }],
    });
    return animals;
  }

  async getAnimal(user: User, id: string, accountId?: string) {
    const accId = this.getAccountId(user, accountId);
    const animal = await this.prisma.animal.findFirst({
      where: { id, account_id: accId },
      include: {
        mother: { select: { id: true, tag_number: true, name: true, breed: true } },
        father: { select: { id: true, tag_number: true, name: true, breed: true } },
        weights: { orderBy: { recorded_at: 'desc' }, take: 50 },
        health_records: { orderBy: { event_date: 'desc' }, take: 50 },
      },
    });
    if (!animal) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Animal not found',
      });
    }
    return animal;
  }

  async getAnimalHistory(user: User, id: string, accountId?: string) {
    const accId = this.getAccountId(user, accountId);
    const animal = await this.prisma.animal.findFirst({
      where: { id, account_id: accId },
      select: { id: true, tag_number: true, name: true },
    });
    if (!animal) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Animal not found',
      });
    }
    const [weights, health_records] = await Promise.all([
      this.prisma.animalWeight.findMany({
        where: { animal_id: id },
        orderBy: { recorded_at: 'desc' },
      }),
      this.prisma.animalHealth.findMany({
        where: { animal_id: id },
        orderBy: { event_date: 'desc' },
      }),
    ]);
    return { ...animal, weights, health_records };
  }

  async createAnimal(
    user: User,
    dto: CreateAnimalDto,
    accountId?: string,
  ) {
    const accId = this.getAccountId(user, accountId);

    const existing = await this.prisma.animal.findUnique({
      where: {
        account_id_tag_number: { account_id: accId, tag_number: dto.tag_number },
      },
    });
    if (existing) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: `An animal with tag number "${dto.tag_number}" already exists in this account.`,
      });
    }

    const data: Prisma.AnimalCreateInput = {
      account: { connect: { id: accId } },
      tag_number: dto.tag_number,
      name: dto.name ?? undefined,
      breed: dto.breed,
      gender: dto.gender as any,
      date_of_birth: new Date(dto.date_of_birth),
      source: dto.source as any,
      purchase_date: dto.purchase_date ? new Date(dto.purchase_date) : undefined,
      purchase_price: dto.purchase_price != null ? dto.purchase_price : undefined,
      status: (dto.status as any) ?? 'active',
      photo_url: dto.photo_url ?? undefined,
      notes: dto.notes ?? undefined,
      created_by: user.id,
    };
    if (dto.mother_id) data.mother = { connect: { id: dto.mother_id } };
    if (dto.father_id) data.father = { connect: { id: dto.father_id } };
    if (dto.farm_id) {
      data.farm = { connect: { id: dto.farm_id } };
    }

    return this.prisma.animal.create({
      data,
      include: {
        mother: { select: { id: true, tag_number: true, name: true } },
        father: { select: { id: true, tag_number: true, name: true } },
      },
    });
  }

  async updateAnimal(
    user: User,
    id: string,
    dto: UpdateAnimalDto,
    accountId?: string,
  ) {
    const accId = this.getAccountId(user, accountId);
    await this.getAnimal(user, id, accountId);

    if (dto.tag_number) {
      const existing = await this.prisma.animal.findFirst({
        where: {
          account_id: accId,
          tag_number: dto.tag_number,
          id: { not: id },
        },
      });
      if (existing) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: `An animal with tag number "${dto.tag_number}" already exists.`,
        });
      }
    }

    const data: Prisma.AnimalUpdateInput = {
      ...(dto.tag_number != null && { tag_number: dto.tag_number }),
      ...(dto.name !== undefined && { name: dto.name }),
      ...(dto.breed != null && { breed: dto.breed }),
      ...(dto.gender != null && { gender: dto.gender as any }),
      ...(dto.date_of_birth != null && { date_of_birth: new Date(dto.date_of_birth) }),
      ...(dto.source != null && { source: dto.source as any }),
      ...(dto.purchase_date !== undefined && {
        purchase_date: dto.purchase_date ? new Date(dto.purchase_date) : null,
      }),
      ...(dto.purchase_price !== undefined && { purchase_price: dto.purchase_price }),
      ...(dto.mother_id !== undefined && {
        mother: dto.mother_id ? { connect: { id: dto.mother_id } } : { disconnect: true },
      }),
      ...(dto.father_id !== undefined && {
        father: dto.father_id ? { connect: { id: dto.father_id } } : { disconnect: true },
      }),
      ...(dto.status != null && { status: dto.status as any }),
      ...(dto.photo_url !== undefined && { photo_url: dto.photo_url }),
      ...(dto.notes !== undefined && { notes: dto.notes }),
      ...(dto.farm_id !== undefined && {
        farm: dto.farm_id ? { connect: { id: dto.farm_id } } : { disconnect: true },
      }),
    };

    return this.prisma.animal.update({
      where: { id },
      data,
      include: {
        mother: { select: { id: true, tag_number: true, name: true } },
        father: { select: { id: true, tag_number: true, name: true } },
      },
    });
  }

  async deleteAnimal(user: User, id: string, accountId?: string) {
    const accId = this.getAccountId(user, accountId);
    const animal = await this.prisma.animal.findFirst({
      where: { id, account_id: accId },
    });
    if (!animal) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Animal not found',
      });
    }
    await this.prisma.animal.delete({ where: { id } });
    return { message: 'Animal deleted successfully' };
  }

  // --- Weights ---
  async addWeight(
    user: User,
    animalId: string,
    dto: CreateAnimalWeightDto,
    accountId?: string,
  ) {
    await this.getAnimal(user, animalId, accountId);
    return this.prisma.animalWeight.create({
      data: {
        animal_id: animalId,
        weight_kg: dto.weight_kg,
        recorded_at: new Date(dto.recorded_at),
        notes: dto.notes ?? undefined,
        created_by: user.id,
      },
    });
  }

  async getWeights(user: User, animalId: string, accountId?: string) {
    await this.getAnimal(user, animalId, accountId);
    return this.prisma.animalWeight.findMany({
      where: { animal_id: animalId },
      orderBy: { recorded_at: 'desc' },
    });
  }

  async deleteWeight(
    user: User,
    animalId: string,
    weightId: string,
    accountId?: string,
  ) {
    await this.getAnimal(user, animalId, accountId);
    const w = await this.prisma.animalWeight.findFirst({
      where: { id: weightId, animal_id: animalId },
    });
    if (!w) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Weight record not found',
      });
    }
    await this.prisma.animalWeight.delete({ where: { id: weightId } });
    return { message: 'Weight record deleted successfully' };
  }

  // --- Health ---
  async addHealth(
    user: User,
    animalId: string,
    dto: CreateAnimalHealthDto,
    accountId?: string,
  ) {
    await this.getAnimal(user, animalId, accountId);
    return this.prisma.animalHealth.create({
      data: {
        animal_id: animalId,
        event_type: dto.event_type as any,
        event_date: new Date(dto.event_date),
        description: dto.description,
        diagnosis: dto.diagnosis ?? undefined,
        treatment: dto.treatment ?? undefined,
        medicine_name: dto.medicine_name ?? undefined,
        dosage: dto.dosage ?? undefined,
        administered_by: dto.administered_by ?? undefined,
        next_due_date: dto.next_due_date ? new Date(dto.next_due_date) : undefined,
        cost: dto.cost != null ? dto.cost : undefined,
        notes: dto.notes ?? undefined,
        created_by: user.id,
      },
    });
  }

  async getHealth(user: User, animalId: string, accountId?: string) {
    await this.getAnimal(user, animalId, accountId);
    return this.prisma.animalHealth.findMany({
      where: { animal_id: animalId },
      orderBy: { event_date: 'desc' },
    });
  }

  async deleteHealth(
    user: User,
    animalId: string,
    healthId: string,
    accountId?: string,
  ) {
    await this.getAnimal(user, animalId, accountId);
    const h = await this.prisma.animalHealth.findFirst({
      where: { id: healthId, animal_id: animalId },
    });
    if (!h) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Health record not found',
      });
    }
    await this.prisma.animalHealth.delete({ where: { id: healthId } });
    return { message: 'Health record deleted successfully' };
  }
}
