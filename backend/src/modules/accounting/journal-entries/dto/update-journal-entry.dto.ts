import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional } from 'class-validator';

export class UpdateJournalEntryDto {
  @ApiProperty({ description: 'Reference number', required: false })
  @IsOptional()
  @IsString()
  reference_number?: string;

  @ApiProperty({ description: 'Description', required: false })
  @IsOptional()
  @IsString()
  description?: string;
}

