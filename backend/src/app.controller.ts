import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Health')
@Controller()
export class AppController {
  @Get()
  @ApiOperation({
    summary: 'Root health check',
    description: 'Returns API status. Base path is /api when using global prefix.',
  })
  @ApiResponse({
    status: 200,
    description: 'API is running',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        service: { type: 'string', example: 'Gemura API' },
        version: { type: 'string', example: '2.0.0' },
        timestamp: { type: 'string', example: '2025-01-19T16:00:00.000Z' },
      },
    },
  })
  getHealth() {
    return {
      status: 'ok',
      service: 'Gemura API',
      version: '2.0.0',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('health')
  @ApiOperation({
    summary: 'Health check',
    description: 'Returns API health status. Use for load balancers and monitoring.',
  })
  @ApiResponse({
    status: 200,
    description: 'API is healthy',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        service: { type: 'string', example: 'Gemura API' },
        version: { type: 'string', example: '2.0.0' },
        timestamp: { type: 'string', example: '2025-01-19T16:00:00.000Z' },
      },
    },
  })
  getHealthCheck() {
    return {
      status: 'ok',
      service: 'Gemura API',
      version: '2.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}

