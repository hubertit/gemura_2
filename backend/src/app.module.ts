import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { SuppliersModule } from './modules/suppliers/suppliers.module';
import { CollectionsModule } from './modules/collections/collections.module';
import { SalesModule } from './modules/sales/sales.module';
import { WalletsModule } from './modules/wallets/wallets.module';
import { ProfileModule } from './modules/profile/profile.module';
import { AppController } from './app.controller';

@Module({
  controllers: [AppController],
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    PrismaModule,
    AuthModule,
    AccountsModule,
    SuppliersModule,
    CollectionsModule,
    SalesModule,
    WalletsModule,
    ProfileModule,
    // TODO: Add modules as they are implemented
    // SuppliersModule,
    // CollectionsModule,
    // SalesModule,
    // AccountingModule,
    // PayrollModule,
  ],
})
export class AppModule {}

