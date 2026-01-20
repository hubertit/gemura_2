import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty } from 'class-validator';

export class ToggleListingDto {
  @ApiProperty({ description: 'Whether to list in marketplace', example: true })
  @IsNotEmpty()
  @IsBoolean()
  is_listed_in_marketplace: boolean;
}
