/**
 * Migration Script Entry Point
 * 
 * Run: npm run migrate
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

  // V2 Database Configuration (PostgreSQL) - from DATABASE_URL
  // DATABASE_URL should be set in .env or environment
  // Format: postgresql://user:password@host:port/database

  console.log('🚀 Starting V1 → V2 Migration...');
  console.log('V1 Database:', v1Config.host, v1Config.database);

  try {
    const results = await migrationService.runMigration(v1Config);

    console.log('\n✅ Migration Results:');
    console.log(`Accounts: ${results.accounts.success} success, ${results.accounts.failed} failed`);
    console.log(`Users: ${results.users.success} success, ${results.users.failed} failed`);
    console.log(`User Accounts: ${results.userAccounts.success} success, ${results.userAccounts.failed} failed`);
    console.log(`Suppliers-Customers: ${results.suppliersCustomers.success} success, ${results.suppliersCustomers.failed} failed`);
    console.log(`Milk Sales: ${results.milkSales.success} success, ${results.milkSales.failed} failed`);
    console.log(`Wallets: ${results.wallets.success} success, ${results.wallets.failed} failed`);

    await app.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    await app.close();
    process.exit(1);
  }
}

bootstrap();

