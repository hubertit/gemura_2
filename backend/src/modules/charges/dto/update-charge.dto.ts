import { PartialType } from '@nestjs/swagger';
import { CreateChargeDto } from './create-charge.dto';

export class UpdateChargeDto extends PartialType(CreateChargeDto) {}
