import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
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
    // TODO: Add modules as they are implemented
    // AuthModule,
    // AccountsModule,
    // SuppliersModule,
    // CollectionsModule,
    // SalesModule,
    // AccountingModule,
    // PayrollModule,
  ],
})
export class AppModule {}

