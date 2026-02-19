/**
 * One-off script: delete all payroll runs from the database.
 * Cascades will remove related payslips, deductions, and charge applications.
 *
 * Run from backend/: npx ts-node scripts/clear-payrolls.ts
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const runs = await prisma.payrollRun.deleteMany({});
  console.log(`Deleted ${runs.count} payroll run(s). Related payslips, deductions, and charge applications were removed by cascade.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
