import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsUUID, Matches } from 'class-validator';

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

export class GetOverviewDto {
  @ApiPropertyOptional({
    description: 'Account ID to get overview for. Uses user default account when omitted.',
  })
  @IsOptional()
  @IsUUID()
  account_id?: string;

  @ApiPropertyOptional({
    description: 'Start of period (YYYY-MM-DD). When omitted, no start filter.',
  })
  @IsOptional()
  @Matches(DATE_ONLY, { message: 'date_from must be YYYY-MM-DD' })
  date_from?: string;

  @ApiPropertyOptional({
    description: 'End of period (YYYY-MM-DD). When omitted, no end filter.',
  })
  @IsOptional()
  @Matches(DATE_ONLY, { message: 'date_to must be YYYY-MM-DD' })
  date_to?: string;
}
