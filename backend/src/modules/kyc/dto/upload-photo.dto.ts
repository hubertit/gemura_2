import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsEnum } from 'class-validator';

export enum KycPhotoType {
  ID_FRONT = 'id_front',
  ID_BACK = 'id_back',
  SELFIE = 'selfie',
}

export class UploadPhotoDto {
  @ApiProperty({
    description: 'Type of KYC photo to upload',
    enum: KycPhotoType,
    example: 'id_front',
  })
  @IsNotEmpty({ message: 'Photo type is required' })
  @IsEnum(KycPhotoType, { message: 'Photo type must be id_front, id_back, or selfie' })
  photo_type: KycPhotoType;

  @ApiProperty({
    description: 'URL of the uploaded photo',
    example: 'https://example.com/uploads/id-front.jpg',
  })
  @IsNotEmpty({ message: 'Photo URL is required' })
  @IsString({ message: 'Photo URL must be a string' })
  photo_url: string;
}

