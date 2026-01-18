/**
 * Selective Migration Script
 * 
 * Migrates only: users, accounts, user_accounts, suppliers_customers
 * Safe to run multiple times - skips already migrated records
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { MigrationService } from './migration.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const migrationService = app.get(MigrationService);

  // V1 Database Configuration (MySQL)
  const v1Config = {
    host: process.env.V1_DB_HOST || 'localhost',
    port: parseInt(process.env.V1_DB_PORT || '3306', 10),
    user: process.env.V1_DB_USER || 'root',
    password: process.env.V1_DB_PASSWORD || 'mysql',
    database: process.env.V1_DB_NAME || 'gemura',
  };

  console.log('🚀 Starting Selective Migration (Users, Accounts, Relationships, Sales)...');
  console.log('V1 Database:', v1Config.host, v1Config.database);
  console.log('V2 Database: From DATABASE_URL');

  try {
    await migrationService.connectV1(v1Config);

    console.log('\n📊 Step 1/5: Migrating accounts...');
    const accounts = await migrationService.migrateAccounts();
    console.log(`   ✅ Accounts: ${accounts.success} migrated, ${accounts.failed} failed`);

    console.log('\n📊 Step 2/5: Migrating users...');
    const users = await migrationService.migrateUsers();
    console.log(`   ✅ Users: ${users.success} migrated, ${users.failed} failed`);

    console.log('\n📊 Step 3/5: Migrating user_accounts relationships...');
    const userAccounts = await migrationService.migrateUserAccounts();
    console.log(`   ✅ User Accounts: ${userAccounts.success} migrated, ${userAccounts.failed} failed`);

    console.log('\n📊 Step 4/5: Migrating suppliers_customers relationships...');
    const suppliersCustomers = await migrationService.migrateSuppliersCustomers();
    console.log(`   ✅ Suppliers-Customers: ${suppliersCustomers.success} migrated, ${suppliersCustomers.failed} failed`);

    console.log('\n📊 Step 5/5: Migrating milk_sales (collections)...');
    const milkSales = await migrationService.migrateMilkSales();
    console.log(`   ✅ Milk Sales: ${milkSales.success} migrated, ${milkSales.failed} failed`);

    await migrationService.disconnectV1();

    console.log('\n✅ Selective Migration Results:');
    console.log(`   Accounts: ${accounts.success} success, ${accounts.failed} failed`);
    console.log(`   Users: ${users.success} success, ${users.failed} failed`);
    console.log(`   User Accounts: ${userAccounts.success} success, ${userAccounts.failed} failed`);
    console.log(`   Suppliers-Customers: ${suppliersCustomers.success} success, ${suppliersCustomers.failed} failed`);
    console.log(`   Milk Sales: ${milkSales.success} success, ${milkSales.failed} failed`);

    await app.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    await migrationService.disconnectV1();
    await app.close();
    process.exit(1);
  }
}

bootstrap();
