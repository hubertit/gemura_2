import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Decorator to extract API key information from the request
 * Use after ApiKeyGuard has validated the request
 */
export const CurrentApiKey = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const apiKey = request.apiKey;

    if (data) {
      return apiKey?.[data];
    }

    return apiKey;
  },
);

/**
 * Decorator to get the account ID from the API key
 * Returns null if the API key has platform-wide access
 */
export const ApiKeyAccountId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string | null => {
    const request = ctx.switchToHttp().getRequest();
    return request.apiKeyAccountId || null;
  },
);

/**
 * Decorator to check if the API key has platform-wide access
 */
export const IsPlatformWide = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): boolean => {
    const request = ctx.switchToHttp().getRequest();
    return request.isPlatformWide === true;
  },
);
