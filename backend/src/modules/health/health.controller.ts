import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ 
    summary: 'Health check endpoint',
    description: 'Returns the health status of the API. Use this endpoint to check if the backend is available and running.'
  })
  @ApiResponse({ 
    status: 200, 
    description: 'API is healthy and running',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        timestamp: { type: 'string', example: '2025-01-19T16:00:00Z' },
        uptime: { type: 'number', example: 3600 },
        version: { type: 'string', example: '2.0.0' }
      }
    }
  })
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: '2.0.0',
    };
  }
}
