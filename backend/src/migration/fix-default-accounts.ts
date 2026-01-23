/**
 * Migration Script: Fix Default Accounts
 * 
 * This script sets a default account for all users who don't have one.
 * It selects the first active account for each user and sets it as their default.
 * 
 * Run: npm run migrate:fix-default-accounts
 * Or: ts-node src/migration/fix-default-accounts.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';

async function fixDefaultAccounts() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const prisma = app.get(PrismaService);

  try {
    console.log('🔍 Finding users without default accounts...');

    // Find all users without a default account
    const usersWithoutDefault = await prisma.user.findMany({
      where: {
        default_account_id: null,
      },
      include: {
        user_accounts: {
          where: {
            status: 'active',
          },
          include: {
            account: true,
          },
          orderBy: {
            created_at: 'asc', // Get the first account (oldest)
          },
          take: 1, // Only need the first account
        },
      },
    });

    console.log(`📊 Found ${usersWithoutDefault.length} users without default accounts`);

    if (usersWithoutDefault.length === 0) {
      console.log('✅ All users already have default accounts!');
      await app.close();
      process.exit(0);
    }

    let fixedCount = 0;
    let skippedCount = 0;

    for (const user of usersWithoutDefault) {
      // Filter to get only active accounts
      const activeUserAccounts = user.user_accounts.filter(
        (ua) => ua.account && ua.account.status === 'active'
      );

      if (activeUserAccounts.length > 0) {
        const firstAccount = activeUserAccounts[0];
        
        // Set the first account as default
        await prisma.user.update({
          where: { id: user.id },
          data: { default_account_id: firstAccount.account.id },
        });

        console.log(
          `✅ Set default account for user ${user.name} (${user.id}): ${firstAccount.account.name} (${firstAccount.account.id})`
        );
        fixedCount++;
      } else {
        console.log(
          `⚠️  User ${user.name} (${user.id}) has no active accounts - skipping`
        );
        skippedCount++;
      }
    }

    console.log('\n📊 Migration Summary:');
    console.log(`   ✅ Fixed: ${fixedCount} users`);
    console.log(`   ⚠️  Skipped: ${skippedCount} users (no active accounts)`);
    console.log(`   📝 Total processed: ${usersWithoutDefault.length} users`);

    await app.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    await app.close();
    process.exit(1);
  }
}

fixDefaultAccounts();
