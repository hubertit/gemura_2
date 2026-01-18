import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam } from '@nestjs/swagger';
import { PayrollSuppliersService } from './payroll-suppliers.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreatePayrollSupplierDto } from './dto/create-payroll-supplier.dto';
import { UpdatePayrollSupplierDto } from './dto/update-payroll-supplier.dto';

@ApiTags('Payroll - Suppliers')
@Controller('payroll/suppliers')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class PayrollSuppliersController {
  constructor(private readonly payrollSuppliersService: PayrollSuppliersService) {}

  @Post()
  @ApiOperation({ summary: 'Create payroll supplier' })
  @ApiBody({ type: CreatePayrollSupplierDto })
  @ApiResponse({ status: 200, description: 'Supplier created successfully' })
  async createSupplier(@CurrentUser() user: User, @Body() createDto: CreatePayrollSupplierDto) {
    return this.payrollSuppliersService.createSupplier(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get payroll suppliers' })
  @ApiResponse({ status: 200, description: 'Suppliers fetched successfully' })
  async getSuppliers(@CurrentUser() user: User) {
    return this.payrollSuppliersService.getSuppliers(user);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get payroll supplier' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Supplier fetched successfully' })
  async getSupplier(@CurrentUser() user: User, @Param('id') id: string) {
    return this.payrollSuppliersService.getSupplier(user, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update payroll supplier' })
  @ApiParam({ name: 'id' })
  @ApiBody({ type: UpdatePayrollSupplierDto })
  @ApiResponse({ status: 200, description: 'Supplier updated successfully' })
  async updateSupplier(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdatePayrollSupplierDto) {
    return this.payrollSuppliersService.updateSupplier(user, id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete payroll supplier' })
  @ApiParam({ name: 'id' })
  @ApiResponse({ status: 200, description: 'Supplier deleted successfully' })
  async deleteSupplier(@CurrentUser() user: User, @Param('id') id: string) {
    return this.payrollSuppliersService.deleteSupplier(user, id);
  }
}

