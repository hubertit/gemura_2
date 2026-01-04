import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SuppliersService } from './suppliers.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateSupplierDto } from './dto/create-supplier.dto';

@ApiTags('Suppliers')
@Controller('suppliers')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class SuppliersController {
  constructor(private readonly suppliersService: SuppliersService) {}

  @Post('create')
  @ApiOperation({ summary: 'Create or update supplier' })
  @ApiResponse({ status: 200, description: 'Supplier created/updated successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  async createSupplier(@CurrentUser() user: User, @Body() createDto: CreateSupplierDto) {
    return this.suppliersService.createOrUpdateSupplier(user, createDto);
  }
}

