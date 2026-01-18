import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreatePayrollSupplierDto } from './dto/create-payroll-supplier.dto';
import { UpdatePayrollSupplierDto } from './dto/update-payroll-supplier.dto';

@Injectable()
export class PayrollSuppliersService {
  constructor(private prisma: PrismaService) {}

  async createSupplier(user: User, createDto: CreatePayrollSupplierDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify supplier account exists
    const supplierAccount = await this.prisma.account.findUnique({
      where: { id: createDto.supplier_account_id },
    });

    if (!supplierAccount) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Supplier account not found.',
      });
    }

    const payrollSupplier = await this.prisma.payrollSupplier.upsert({
      where: { supplier_account_id: createDto.supplier_account_id },
      update: {
        payment_terms_days: createDto.payment_terms_days || 15,
        is_active: true,
      },
      create: {
        supplier_account_id: createDto.supplier_account_id,
        payment_terms_days: createDto.payment_terms_days || 15,
        is_active: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll supplier created successfully.',
      data: {
        id: payrollSupplier.id,
        supplier_account_id: payrollSupplier.supplier_account_id,
        payment_terms_days: payrollSupplier.payment_terms_days,
      },
    };
  }

  async getSuppliers(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const suppliers = await this.prisma.payrollSupplier.findMany({
      where: {
        is_active: true,
      },
      include: {
        supplier_account: {
          select: {
            id: true,
            code: true,
            name: true,
            type: true,
            status: true,
          },
        },
      },
      orderBy: {
        supplier_account: {
          name: 'asc',
        },
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll suppliers fetched successfully.',
      data: suppliers.map((s) => ({
        id: s.id,
        supplier: {
          id: s.supplier_account.id,
          code: s.supplier_account.code,
          name: s.supplier_account.name,
        },
        payment_terms_days: s.payment_terms_days,
      })),
    };
  }

  async getSupplier(user: User, supplierId: string) {
    const supplier = await this.prisma.payrollSupplier.findUnique({
      where: { id: supplierId },
      include: {
        supplier_account: true,
        payslips: {
          orderBy: { created_at: 'desc' },
          take: 10,
        },
      },
    });

    if (!supplier) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll supplier not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Payroll supplier fetched successfully.',
      data: {
        id: supplier.id,
        supplier: supplier.supplier_account,
        payment_terms_days: supplier.payment_terms_days,
        recent_payslips: supplier.payslips,
      },
    };
  }

  async updateSupplier(user: User, supplierId: string, updateDto: UpdatePayrollSupplierDto) {
    const supplier = await this.prisma.payrollSupplier.findUnique({ where: { id: supplierId } });
    if (!supplier) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll supplier not found.',
      });
    }

    const updated = await this.prisma.payrollSupplier.update({
      where: { id: supplierId },
      data: {
        payment_terms_days: updateDto.payment_terms_days !== undefined ? updateDto.payment_terms_days : supplier.payment_terms_days,
        is_active: updateDto.is_active !== undefined ? updateDto.is_active : supplier.is_active,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll supplier updated successfully.',
      data: updated,
    };
  }

  async deleteSupplier(user: User, supplierId: string) {
    const supplier = await this.prisma.payrollSupplier.findUnique({ where: { id: supplierId } });
    if (!supplier) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Payroll supplier not found.',
      });
    }

    await this.prisma.payrollSupplier.update({
      where: { id: supplierId },
      data: { is_active: false },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll supplier deleted successfully.',
    };
  }
}

