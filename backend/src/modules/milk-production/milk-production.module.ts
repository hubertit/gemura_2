import { Module } from '@nestjs/common';
import { MilkProductionController } from './milk-production.controller';
import { MilkProductionService } from './milk-production.service';

@Module({
  controllers: [MilkProductionController],
  providers: [MilkProductionService],
  exports: [MilkProductionService],
})
export class MilkProductionModule {}
