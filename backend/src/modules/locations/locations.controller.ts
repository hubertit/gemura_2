import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiParam, ApiBearerAuth } from '@nestjs/swagger';
import { TokenGuard } from '../../common/guards/token.guard';
import { LocationsService } from './locations.service';

@ApiTags('Locations')
@Controller('locations')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class LocationsController {
  constructor(private readonly locationsService: LocationsService) {}

  @Get('provinces')
  @ApiOperation({ summary: 'List provinces', description: 'Returns all provinces (top-level admin units).' })
  async getProvinces() {
    const data = await this.locationsService.getProvinces();
    return { code: 200, status: 'success', message: 'Provinces retrieved', data };
  }

  @Get()
  @ApiOperation({
    summary: 'List children of a location',
    description: 'Returns direct children of the given parent_id (e.g. districts of a province, sectors of a district).',
  })
  @ApiQuery({ name: 'parent_id', required: true, description: 'Parent location UUID' })
  async getChildren(@Query('parent_id') parentId: string) {
    const data = await this.locationsService.getChildren(parentId);
    return { code: 200, status: 'success', message: 'Locations retrieved', data };
  }

  @Get(':id/path')
  @ApiOperation({
    summary: 'Get location path',
    description: 'Returns the path from this location up to root (e.g. village → cell → sector → district → province).',
  })
  @ApiParam({ name: 'id', description: 'Location UUID' })
  async getPath(@Param('id') id: string) {
    const data = await this.locationsService.getPath(id);
    return { code: 200, status: 'success', message: 'Path retrieved', data };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get location by ID' })
  @ApiParam({ name: 'id', description: 'Location UUID' })
  async getById(@Param('id') id: string) {
    const data = await this.locationsService.getById(id);
    if (!data) {
      return { code: 404, status: 'error', message: 'Location not found', data: null };
    }
    return { code: 200, status: 'success', message: 'Location retrieved', data };
  }
}
