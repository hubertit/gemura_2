import { Controller, Post, Get, Put, Delete, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiBadRequestResponse, ApiUnauthorizedResponse, ApiNotFoundResponse, ApiForbiddenResponse, ApiParam } from '@nestjs/swagger';
import { EmployeesService } from './employees.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';

@ApiTags('Employees')
@Controller('employees')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class EmployeesController {
  constructor(private readonly employeesService: EmployeesService) {}

  @Post()
  @ApiOperation({
    summary: 'Create employee',
    description: 'Add a user as an employee to your account. Requires owner or admin role.',
  })
  @ApiBody({ type: CreateEmployeeDto })
  @ApiResponse({
    status: 200,
    description: 'Employee added successfully',
  })
  @ApiBadRequestResponse({ description: 'Invalid request' })
  @ApiForbiddenResponse({ description: 'Insufficient permissions' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async createEmployee(@CurrentUser() user: User, @Body() createDto: CreateEmployeeDto) {
    return this.employeesService.createEmployee(user, createDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Get employees',
    description: 'Get all employees for your default account.',
  })
  @ApiResponse({
    status: 200,
    description: 'Employees fetched successfully',
  })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getEmployees(@CurrentUser() user: User) {
    return this.employeesService.getEmployees(user);
  }

  @Put(':id/access')
  @ApiOperation({
    summary: 'Update employee access',
    description: 'Update employee role, permissions, or status. Requires owner or admin role.',
  })
  @ApiParam({ name: 'id', description: 'Employee (UserAccount) ID' })
  @ApiBody({ type: UpdateEmployeeDto })
  @ApiResponse({
    status: 200,
    description: 'Employee updated successfully',
  })
  @ApiNotFoundResponse({ description: 'Employee not found' })
  @ApiForbiddenResponse({ description: 'Insufficient permissions' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async updateEmployee(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdateEmployeeDto) {
    return this.employeesService.updateEmployee(user, id, updateDto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete employee',
    description: 'Remove an employee from your account (soft delete). Requires owner or admin role.',
  })
  @ApiParam({ name: 'id', description: 'Employee (UserAccount) ID' })
  @ApiResponse({
    status: 200,
    description: 'Employee removed successfully',
  })
  @ApiNotFoundResponse({ description: 'Employee not found' })
  @ApiForbiddenResponse({ description: 'Insufficient permissions' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async deleteEmployee(@CurrentUser() user: User, @Param('id') id: string) {
    return this.employeesService.deleteEmployee(user, id);
  }
}

