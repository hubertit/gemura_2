import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Get the account ID from request (body, query, or user's default account)
 */
export const CurrentAccount = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    
    // Try to get from body first
    if (request.body?.account_id) {
      return request.body.account_id;
    }
    
    // Try query parameter
    if (request.query?.account_id) {
      return request.query.account_id;
    }
    
    // Fall back to user's default account
    return user?.default_account_id;
  },
);
