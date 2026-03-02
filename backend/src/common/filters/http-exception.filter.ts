import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';

/**
 * Global exception filter so unhandled errors return a valid JSON response
 * instead of crashing the request (which can cause nginx to return 502).
 * Affects all routes (animals, farms, stats, collections, etc.).
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let body: Record<string, unknown> = {
      code: 500,
      status: 'error',
      message: 'An unexpected error occurred.',
    };

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'object' && res !== null && !Array.isArray(res)) {
        body = { code: status, status: 'error', ...(res as object) } as Record<string, unknown>;
      } else {
        body.message = String(res);
      }
    } else if (exception instanceof Error) {
      this.logger.error(
        `Unhandled exception: ${exception.message}`,
        exception.stack,
      );
      body.message = process.env.NODE_ENV === 'production'
        ? 'An unexpected error occurred.'
        : exception.message;
    }

    try {
      response.status(status).json(body);
    } catch (sendError) {
      this.logger.error('Failed to send error response', sendError);
      try {
        response.status(status).end();
      } catch {
        // Connection may already be closed
      }
    }
  }
}
