import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { ImmisService } from './immis.service';
import { ImmisController } from './immis.controller';

@Module({
  imports: [PrismaModule],
  providers: [ImmisService],
  controllers: [ImmisController],
  exports: [ImmisService],
})
export class ImmisModule {}

