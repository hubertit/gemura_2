# API Documentation Roadmap

## Current Status

✅ **Completed:**
- Created comprehensive Swagger documentation standards
- Updated `accounting/reports/reports.controller.ts` with complete documentation
- Created documentation status tracking
- Established consistent patterns and examples

## Next Steps

### Phase 1: High Priority Controllers (Core Financial Features)
These controllers handle critical financial operations and should be documented first:

1. `accounting/receivables-payables/receivables-payables.controller.ts`
2. `wallets.controller.ts`
3. `sales.controller.ts`
4. `collections.controller.ts`
5. `suppliers.controller.ts`
6. `customers.controller.ts`

**Estimated Time:** 2-3 hours

### Phase 2: Medium Priority Controllers (Business Operations)
7. `inventory.controller.ts`
8. `payroll/runs/payroll-runs.controller.ts`
9. `payroll/periods/payroll-periods.controller.ts`
10. `payroll/suppliers/payroll-suppliers.controller.ts`
11. `payroll/reports/payroll-reports.controller.ts`

**Estimated Time:** 3-4 hours

### Phase 3: Supporting Features
12. `market/products/products.controller.ts`
13. `market/orders/orders.controller.ts`
14. `market/categories/categories.controller.ts`
15. `feed/posts/posts.controller.ts`
16. `feed/comments/comments.controller.ts`
17. `feed/stories/stories.controller.ts`
18. `feed/interactions/interactions.controller.ts`
19. `feed/relationships/relationships.controller.ts`
20. `notifications.controller.ts`
21. `profile.controller.ts`
22. `stats.controller.ts`
23. `analytics.controller.ts`
24. `employees.controller.ts`
25. `referrals.controller.ts`
26. `points.controller.ts`
27. `onboard.controller.ts`
28. `admin.controller.ts`
29. `kyc.controller.ts`
30. `api-keys.controller.ts`
31. `media.controller.ts`
32. `auth.controller.ts` (enhance existing)

**Estimated Time:** 6-8 hours

## Documentation Checklist for Each Controller

When updating a controller, ensure:

- [ ] All endpoints have `@ApiOperation` with summary and description
- [ ] All endpoints have `@ApiResponse` for 200 (success) with example
- [ ] All endpoints have error responses (400, 401, 403, 404) with examples
- [ ] All POST/PUT/PATCH endpoints have `@ApiBody` with examples
- [ ] All query parameters have `@ApiQuery` with description and example
- [ ] All path parameters have `@ApiParam` with description and example
- [ ] All DTOs have `@ApiProperty` with examples
- [ ] Examples use realistic values (Rwandan context)
- [ ] Descriptions explain account scoping where applicable

## Guidelines

1. **Follow the Standard**: Use `docs/backend/SWAGGER_DOCUMENTATION_STANDARDS.md` as reference
2. **Use Realistic Examples**: 
   - UUIDs: `'550e8400-e29b-41d4-a716-446655440000'`
   - Dates: `'2025-01-28'` or `'2025-01-28T10:30:00Z'`
   - Phone: `'250788123456'`
   - Amounts: `150000` (RWF)
   - Names: `'John Doe'`, `'KOPERATIVE KOZAMGI'`
3. **Account Scoping**: Mention in descriptions when endpoints are scoped to user's default account
4. **Consistency**: Follow the pattern in `accounts.controller.ts` and `accounting/reports/reports.controller.ts`

## Tools

- Swagger UI: `http://localhost:3004/api/docs` (when backend is running)
- Review existing well-documented controllers for patterns
- Use the standards document as reference

## Notes

- Documentation is an ongoing process
- Update `API_DOCUMENTATION_STATUS.md` as controllers are completed
- Prioritize based on API usage and importance
- Consider creating DTO examples file for reusable examples
