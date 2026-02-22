import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { SmsService } from './services/sms.service';
import { EmailService } from './services/email.service';
import { ApiKeyGuard } from './guards/api-key.guard';
import { TokenGuard } from './guards/token.guard';

@Module({
  imports: [PrismaModule],
  providers: [SmsService, EmailService, ApiKeyGuard, TokenGuard],
  exports: [SmsService, EmailService, ApiKeyGuard, TokenGuard],
})
export class CommonModule {}
