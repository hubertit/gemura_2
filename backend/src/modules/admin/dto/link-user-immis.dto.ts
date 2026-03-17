import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min, ValidateIf } from 'class-validator';

/** Use a positive IMMIS member id to link, or `null` to remove the link. */
export class LinkUserImmisDto {
  @ApiProperty({ nullable: true, example: 10, description: 'IMMIS member id, or null to unlink' })
  @ValidateIf((_, v) => v !== null)
  @IsInt()
  @Min(1)
  immis_member_id: number | null;
}
