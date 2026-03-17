import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

export class LinkImmisDto {
  @ApiProperty({ example: 10, description: 'IMMIS member id (from IMMIS list or certificate)' })
  @IsInt()
  @Min(1)
  immis_member_id: number;
}
