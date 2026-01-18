import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreatePayrollPeriodDto } from './dto/create-payroll-period.dto';

@Injectable()
export class PayrollPeriodsService {
  constructor(private prisma: PrismaService) {}

  async createPeriod(user: User, createDto: CreatePayrollPeriodDto) {
    const period = await this.prisma.payrollPeriod.create({
      data: {
        period_name: createDto.period_name,
        start_date: new Date(createDto.start_date),
        end_date: new Date(createDto.end_date),
        status: 'draft',
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll period created successfully.',
      data: {
        id: period.id,
        period_name: period.period_name,
        start_date: period.start_date,
        end_date: period.end_date,
        status: period.status,
      },
    };
  }

  async getPeriods(user: User) {
    const periods = await this.prisma.payrollPeriod.findMany({
      include: {
        runs: {
          orderBy: { run_date: 'desc' },
          take: 5,
        },
      },
      orderBy: { start_date: 'desc' },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Payroll periods fetched successfully.',
      data: periods.map((p) => ({
        id: p.id,
        period_name: p.period_name,
        start_date: p.start_date,
        end_date: p.end_date,
        status: p.status,
        runs_count: p.runs.length,
      })),
    };
  }
}

