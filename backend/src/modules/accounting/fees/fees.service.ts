import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateFeeTypeDto } from './dto/create-fee-type.dto';
import { CreateFeeRuleDto } from './dto/create-fee-rule.dto';
import { CreateDeductionDto } from './dto/create-deduction.dto';

@Injectable()
export class FeesService {
  constructor(private prisma: PrismaService) {}

  async createFeeType(user: User, createDto: CreateFeeTypeDto) {
    const feeType = await this.prisma.feeType.create({
      data: {
        code: createDto.code,
        name: createDto.name,
        description: createDto.description,
        fee_category: createDto.fee_category,
        calculation_type: createDto.calculation_type,
        is_active: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Fee type created successfully.',
      data: feeType,
    };
  }

  async getFeeTypes(user: User) {
    const feeTypes = await this.prisma.feeType.findMany({
      where: { is_active: true },
      orderBy: { name: 'asc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Fee types fetched successfully.',
      data: feeTypes,
    };
  }

  async createFeeRule(user: User, createDto: CreateFeeRuleDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const feeRule = await this.prisma.supplierFeeRule.create({
      data: {
        supplier_account_id: createDto.supplier_account_id || user.default_account_id,
        fee_type_id: createDto.fee_type_id,
        fixed_amount: createDto.fixed_amount || null,
        percentage: createDto.percentage || null,
        min_amount: createDto.min_amount || null,
        max_amount: createDto.max_amount || null,
        is_active: true,
        effective_from: new Date(createDto.effective_from),
        effective_to: createDto.effective_to ? new Date(createDto.effective_to) : null,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Fee rule created successfully.',
      data: feeRule,
    };
  }

  async getFeeRules(user: User, supplierAccountId?: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const feeRules = await this.prisma.supplierFeeRule.findMany({
      where: {
        supplier_account_id: supplierAccountId || user.default_account_id,
        is_active: true,
      },
      include: {
        fee_type: true,
      },
      orderBy: { effective_from: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Fee rules fetched successfully.',
      data: feeRules,
    };
  }

  async createDeduction(user: User, createDto: CreateDeductionDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const deduction = await this.prisma.supplierDeduction.create({
      data: {
        supplier_account_id: createDto.supplier_account_id || user.default_account_id,
        fee_type_id: createDto.fee_type_id,
        milk_sale_id: createDto.milk_sale_id || null,
        amount: createDto.amount,
        description: createDto.description,
        applied_at: new Date(createDto.applied_at || new Date()),
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Deduction created successfully.',
      data: deduction,
    };
  }

  async getDeductions(user: User, supplierAccountId?: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const deductions = await this.prisma.supplierDeduction.findMany({
      where: {
        supplier_account_id: supplierAccountId || user.default_account_id,
      },
      include: {
        fee_type: true,
        milk_sale: true,
      },
      orderBy: { applied_at: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Deductions fetched successfully.',
      data: deductions.map((d) => ({
        id: d.id,
        fee_type: d.fee_type.name,
        amount: Number(d.amount),
        description: d.description,
        applied_at: d.applied_at,
      })),
    };
  }
}

