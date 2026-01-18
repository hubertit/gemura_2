import { Module } from '@nestjs/common';
import { MigrationService } from './migration.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [MigrationService],
  exports: [MigrationService],
})
export class MigrationModule {}

