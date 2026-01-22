import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
  ApiParam,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { PermissionGuard } from '../../common/guards/permission.guard';
import { RequirePermission, RequireRole } from '../../common/decorators/permission.decorator';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { CurrentAccount } from '../../common/decorators/account.decorator';
import { User } from '@prisma/client';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@ApiTags('Admin')
@Controller('admin')
@UseGuards(TokenGuard, PermissionGuard)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard/stats')
  @RequirePermission('dashboard.view')
  @ApiOperation({ summary: 'Get admin dashboard statistics' })
  @ApiResponse({ status: 200, description: 'Dashboard statistics retrieved successfully' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async getDashboardStats(
    @CurrentUser() user: User,
    @CurrentAccount() accountId: string,
  ) {
    return this.adminService.getDashboardStats(user, accountId);
  }

  @Get('users')
  @RequirePermission('manage_users')
  @ApiOperation({ summary: 'Get all users with pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Users retrieved successfully' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async getUsers(
    @CurrentUser() user: User,
    @CurrentAccount() accountId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.adminService.getUsers(user, accountId, pageNum, limitNum, search);
  }

  @Get('users/:id')
  @RequirePermission('manage_users')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'id', type: String })
  @ApiResponse({ status: 200, description: 'User retrieved successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async getUserById(
    @CurrentUser() user: User,
    @CurrentAccount() accountId: string,
    @Param('id') userId: string,
  ) {
    return this.adminService.getUserById(user, accountId, userId);
  }

  @Post('users')
  @RequirePermission('manage_users')
  @ApiOperation({ summary: 'Create new user' })
  @ApiResponse({ status: 201, description: 'User created successfully' })
  @ApiResponse({ status: 400, description: 'Validation error or email/phone already exists' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async createUser(
    @CurrentUser() user: User,
    @CurrentAccount() accountId: string,
    @Body() createDto: CreateUserDto,
  ) {
    return this.adminService.createUser(user, accountId, createDto);
  }

  @Put('users/:id')
  @RequirePermission('manage_users')
  @ApiOperation({ summary: 'Update user' })
  @ApiParam({ name: 'id', type: String })
  @ApiResponse({ status: 200, description: 'User updated successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async updateUser(
    @CurrentUser() user: User,
    @CurrentAccount() accountId: string,
    @Param('id') userId: string,
    @Body() updateDto: UpdateUserDto,
  ) {
    return this.adminService.updateUser(user, accountId, userId, updateDto);
  }

  @Delete('users/:id')
  @RequirePermission('manage_users')
  @ApiOperation({ summary: 'Delete user (soft delete)' })
  @ApiParam({ name: 'id', type: String })
  @ApiResponse({ status: 200, description: 'User deleted successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Insufficient permissions' })
  async deleteUser(
    @CurrentUser() user: User,
    @CurrentAccount() accountId: string,
    @Param('id') userId: string,
  ) {
    return this.adminService.deleteUser(user, accountId, userId);
  }
}
