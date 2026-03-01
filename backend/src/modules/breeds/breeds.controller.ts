import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { BreedsService } from './breeds.service';
import { TokenGuard } from '../../common/guards/token.guard';

@ApiTags('Breeds')
@Controller('breeds')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class BreedsController {
  constructor(private readonly breedsService: BreedsService) {}

  @Get()
  @ApiOperation({ summary: 'List breeds', description: 'List all predefined breeds for animal registration/editing.' })
  @ApiResponse({ status: 200, description: 'List of breeds (id, name, code, description)' })
  @ApiUnauthorizedResponse({ description: 'Unauthorized' })
  async findAll() {
    const data = await this.breedsService.findAll();
    return { code: 200, status: 'success', message: 'Breeds retrieved', data };
  }
}
