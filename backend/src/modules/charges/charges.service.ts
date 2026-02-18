import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateChargeDto } from './dto/create-charge.dto';
import { UpdateChargeDto } from './dto/update-charge.dto';
import { Decimal } from '@prisma/client/runtime/library';

export interface ApplicableCharge {
  chargeId: string;
  name: string;
  amount: number;
  kind: string; // one_time | recurring (so payroll can record application for one-time only)
}

@Injectable()
export class ChargesService {
  constructor(private prisma: PrismaService) {}

  private getCustomerAccountId(user: User, accountIdParam?: string): string {
    if (accountIdParam) {
      return accountIdParam;
    }
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found. Please set a default account.',
      });
    }
    return user.default_account_id;
  }

  async create(user: User, dto: CreateChargeDto, accountIdParam?: string) {
    const customerAccountId = this.getCustomerAccountId(user, accountIdParam);

    if (dto.kind === 'recurring' && !dto.recurrence) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Recurrence is required for recurring charges (monthly or per_payroll).',
      });
    }

    if (dto.amount_type === 'percentage' && (dto.amount < 0 || dto.amount > 100)) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Percentage must be between 0 and 100.',
      });
    }

    const effectiveFrom = dto.effective_from ? new Date(dto.effective_from) : null;
    const effectiveTo = dto.effective_to ? new Date(dto.effective_to) : null;

    const charge = await this.prisma.charge.create({
      data: {
        customer_account_id: customerAccountId,
        name: dto.name,
        description: dto.description ?? null,
        kind: dto.kind,
        amount_type: dto.amount_type,
        amount: new Decimal(dto.amount),
        recurrence: dto.recurrence ?? null,
        apply_to_all_suppliers: dto.apply_to_all_suppliers ?? true,
        effective_from: effectiveFrom,
        effective_to: effectiveTo,
        is_active: dto.is_active ?? true,
        created_by: user.id,
      },
    });

    if (!(dto.apply_to_all_suppliers ?? true) && dto.supplier_account_ids?.length) {
      await this.prisma.chargeSupplier.createMany({
        data: dto.supplier_account_ids.map((supplier_account_id) => ({
          charge_id: charge.id,
          supplier_account_id,
        })),
        skipDuplicates: true,
      });
    }

    return this.findOne(user, charge.id, accountIdParam);
  }

  async findAll(user: User, accountIdParam?: string, activeOnly = false) {
    const customerAccountId = this.getCustomerAccountId(user, accountIdParam);

    const where: any = { customer_account_id: customerAccountId };
    if (activeOnly) {
      where.is_active = true;
    }

    const charges = await this.prisma.charge.findMany({
      where,
      include: {
        selected_suppliers: {
          include: {
            supplier: { select: { id: true, code: true, name: true } },
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Charges fetched successfully.',
      data: charges.map((c) => ({
        id: c.id,
        name: c.name,
        description: c.description,
        kind: c.kind,
        amount_type: c.amount_type,
        amount: Number(c.amount),
        recurrence: c.recurrence,
        apply_to_all_suppliers: c.apply_to_all_suppliers,
        effective_from: c.effective_from?.toISOString().slice(0, 10) ?? null,
        effective_to: c.effective_to?.toISOString().slice(0, 10) ?? null,
        is_active: c.is_active,
        created_at: c.created_at,
        selected_suppliers: c.selected_suppliers.map((s) => ({
          id: s.supplier.id,
          code: s.supplier.code,
          name: s.supplier.name,
        })),
      })),
    };
  }

  async findOne(user: User, id: string, accountIdParam?: string) {
    const customerAccountId = this.getCustomerAccountId(user, accountIdParam);

    const charge = await this.prisma.charge.findFirst({
      where: { id, customer_account_id: customerAccountId },
      include: {
        selected_suppliers: {
          include: {
            supplier: { select: { id: true, code: true, name: true } },
          },
        },
      },
    });

    if (!charge) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Charge not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Charge fetched successfully.',
      data: {
        id: charge.id,
        name: charge.name,
        description: charge.description,
        kind: charge.kind,
        amount_type: charge.amount_type,
        amount: Number(charge.amount),
        recurrence: charge.recurrence,
        apply_to_all_suppliers: charge.apply_to_all_suppliers,
        effective_from: charge.effective_from?.toISOString().slice(0, 10) ?? null,
        effective_to: charge.effective_to?.toISOString().slice(0, 10) ?? null,
        is_active: charge.is_active,
        created_at: charge.created_at,
        updated_at: charge.updated_at,
        selected_suppliers: charge.selected_suppliers.map((s) => ({
          id: s.supplier.id,
          code: s.supplier.code,
          name: s.supplier.name,
        })),
      },
    };
  }

  async update(user: User, id: string, dto: UpdateChargeDto, accountIdParam?: string) {
    const customerAccountId = this.getCustomerAccountId(user, accountIdParam);

    const existing = await this.prisma.charge.findFirst({
      where: { id, customer_account_id: customerAccountId },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Charge not found.',
      });
    }

    if (dto.kind === 'recurring' && dto.recurrence === undefined && existing.recurrence === null) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Recurrence is required for recurring charges (monthly or per_payroll).',
      });
    }

    const effectiveFrom = dto.effective_from !== undefined ? (dto.effective_from ? new Date(dto.effective_from) : null) : undefined;
    const effectiveTo = dto.effective_to !== undefined ? (dto.effective_to ? new Date(dto.effective_to) : null) : undefined;

    await this.prisma.charge.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.kind !== undefined && { kind: dto.kind }),
        ...(dto.amount_type !== undefined && { amount_type: dto.amount_type }),
        ...(dto.amount !== undefined && { amount: new Decimal(dto.amount) }),
        ...(dto.recurrence !== undefined && { recurrence: dto.recurrence }),
        ...(dto.apply_to_all_suppliers !== undefined && { apply_to_all_suppliers: dto.apply_to_all_suppliers }),
        ...(effectiveFrom !== undefined && { effective_from: effectiveFrom }),
        ...(effectiveTo !== undefined && { effective_to: effectiveTo }),
        ...(dto.is_active !== undefined && { is_active: dto.is_active }),
      },
    });

    if (dto.apply_to_all_suppliers === true) {
      await this.prisma.chargeSupplier.deleteMany({ where: { charge_id: id } });
    } else if (dto.apply_to_all_suppliers === false && dto.supplier_account_ids !== undefined) {
      await this.prisma.chargeSupplier.deleteMany({ where: { charge_id: id } });
      if (dto.supplier_account_ids.length > 0) {
        await this.prisma.chargeSupplier.createMany({
          data: dto.supplier_account_ids.map((supplier_account_id) => ({
            charge_id: id,
            supplier_account_id,
          })),
          skipDuplicates: true,
        });
      }
    }

    return this.findOne(user, id, accountIdParam);
  }

  async remove(user: User, id: string, accountIdParam?: string) {
    const customerAccountId = this.getCustomerAccountId(user, accountIdParam);

    const existing = await this.prisma.charge.findFirst({
      where: { id, customer_account_id: customerAccountId },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Charge not found.',
      });
    }

    await this.prisma.charge.delete({ where: { id } });

    return {
      code: 200,
      status: 'success',
      message: 'Charge deleted successfully.',
    };
  }

  /**
   * Used by Payroll when generating payslips: returns charges applicable to this supplier for the period.
   * - Recurring (per_payroll): included every time; amount = fixed or percentage of gross.
   * - Recurring (monthly): included if period overlaps the month (simplified: if period contains any day of current month).
   * - One-time: included only if not already applied (no ChargeApplication for this charge+supplier).
   */
  async getApplicableChargesForPayroll(
    customerAccountId: string,
    supplierAccountId: string,
    periodStart: Date,
    periodEnd: Date,
    grossAmount: number,
  ): Promise<ApplicableCharge[]> {
    const now = new Date();
    const results: ApplicableCharge[] = [];

    const charges = await this.prisma.charge.findMany({
      where: {
        customer_account_id: customerAccountId,
        is_active: true,
        effective_from: { lte: periodEnd },
        AND: [
          { OR: [{ effective_to: null }, { effective_to: { gte: periodStart } }] },
          {
            OR: [
              { apply_to_all_suppliers: true },
              {
                apply_to_all_suppliers: false,
                selected_suppliers: {
                  some: { supplier_account_id: supplierAccountId },
                },
              },
            ],
          },
        ],
      },
      orderBy: { created_at: 'asc' },
    });

    for (const charge of charges) {
      if (charge.kind === 'one_time') {
        const alreadyApplied = await this.prisma.chargeApplication.findUnique({
          where: {
            charge_id_supplier_account_id: {
              charge_id: charge.id,
              supplier_account_id: supplierAccountId,
            },
          },
        });
        if (alreadyApplied) continue;
      } else {
        // recurring
        if (charge.recurrence === 'monthly') {
          // Include if period overlaps any month (simplified: include if period is within effective dates)
          // Already filtered by effective_from/effective_to above
        }
        // per_payroll: always include for the run
      }

      let amount: number;
      if (charge.amount_type === 'fixed') {
        amount = Number(charge.amount);
      } else {
        amount = (grossAmount * Number(charge.amount)) / 100;
        amount = Math.round(amount * 100) / 100;
      }

      if (amount > 0) {
        results.push({
          chargeId: charge.id,
          name: charge.name,
          amount,
          kind: charge.kind,
        });
      }
    }

    return results;
  }

  /**
   * Record that a one-time charge was applied (called by Payroll when creating the deduction).
   */
  async recordChargeApplication(
    chargeId: string,
    supplierAccountId: string,
    payslipId: string,
    amount: number,
  ): Promise<void> {
    await this.prisma.chargeApplication.create({
      data: {
        charge_id: chargeId,
        supplier_account_id: supplierAccountId,
        payslip_id: payslipId,
        amount: new Decimal(amount),
      },
    });
  }
}
