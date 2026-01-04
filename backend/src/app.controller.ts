import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Health')
@Controller()
export class AppController {
  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  getHealth() {
    return {
      status: 'ok',
      service: 'Gemura API',
      version: '2.0.0',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('health')
  @ApiOperation({ summary: 'Health check endpoint' })
  getHealthCheck() {
    return {
      status: 'ok',
      service: 'Gemura API',
      version: '2.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}

