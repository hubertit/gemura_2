/**
 * Set the account for a user (by phone) to type 'admin'.
 * Run after migration that adds 'admin' to AccountType.
 * Usage: npx ts-node prisma/set-account-admin.ts [phone]
 * Example: npx ts-node prisma/set-account-admin.ts 250788606765
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const phone = (process.argv[2] || '250788606765').replace(/\D/g, '');
  if (!phone) {
    console.error('Usage: npx ts-node prisma/set-account-admin.ts [phone]');
    process.exit(1);
  }

  const user = await prisma.user.findFirst({
    where: { phone },
    include: {
      user_accounts: {
        include: { account: true },
        orderBy: { created_at: 'asc' },
      },
    },
  });

  if (!user) {
    console.error(`User not found with phone: ${phone}`);
    process.exit(1);
  }

  const accountToUpdate = user.default_account_id
    ? user.user_accounts.find((ua) => ua.account_id === user.default_account_id)?.account
    : user.user_accounts[0]?.account;

  if (!accountToUpdate) {
    console.error('User has no linked account');
    process.exit(1);
  }

  await prisma.account.update({
    where: { id: accountToUpdate.id },
    data: { type: 'admin' },
  });

  console.log(`✅ Account "${accountToUpdate.name}" (${accountToUpdate.code}) set to type 'admin'.`);
  console.log(`   User: ${user.name} (${user.phone}). Log in and switch to this account to see admin menu.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
