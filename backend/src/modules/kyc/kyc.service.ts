import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { UploadPhotoDto, KycPhotoType } from './dto/upload-photo.dto';

@Injectable()
export class KycService {
  constructor(private prisma: PrismaService) {}

  async uploadPhoto(user: User, uploadDto: UploadPhotoDto) {
    const { photo_type, photo_url } = uploadDto;

    const updateData: any = {
      kyc_status: 'pending',
    };

    // Update the appropriate photo field based on type
    switch (photo_type) {
      case KycPhotoType.ID_FRONT:
        updateData.id_front_photo_url = photo_url;
        break;
      case KycPhotoType.ID_BACK:
        updateData.id_back_photo_url = photo_url;
        break;
      case KycPhotoType.SELFIE:
        updateData.selfie_photo_url = photo_url;
        break;
      default:
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Invalid photo type.',
        });
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: user.id },
      data: updateData,
      select: {
        id: true,
        kyc_status: true,
        id_front_photo_url: true,
        id_back_photo_url: true,
        selfie_photo_url: true,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'KYC photo uploaded successfully.',
      data: {
        user_id: updatedUser.id,
        photo_type: photo_type,
        photo_url: photo_url,
        kyc_status: updatedUser.kyc_status,
        kyc_photos: {
          id_front: updatedUser.id_front_photo_url,
          id_back: updatedUser.id_back_photo_url,
          selfie: updatedUser.selfie_photo_url,
        },
      },
    };
  }
}

