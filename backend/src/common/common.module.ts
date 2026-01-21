import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { SmsService } from './services/sms.service';
import { EmailService } from './services/email.service';

@Module({
  imports: [PrismaModule],
  providers: [SmsService, EmailService],
  exports: [SmsService, EmailService],
})
export class CommonModule {}
