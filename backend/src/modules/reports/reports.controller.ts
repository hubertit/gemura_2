import { Controller, Post, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';

@ApiTags('Reports')
@Controller('reports')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post('my-report')
  @HttpCode(200)
  @ApiOperation({ summary: 'Get user report' })
  @ApiResponse({ status: 200, description: 'Report generated successfully' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async getMyReport(@CurrentUser() user: User) {
    return this.reportsService.getMyReport(user);
  }
}

