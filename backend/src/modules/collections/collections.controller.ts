import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CollectionsService } from './collections.service';
import { TokenGuard } from '../../common/guards/token.guard';
import { CurrentUser } from '../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateCollectionDto } from './dto/create-collection.dto';

@ApiTags('Collections')
@Controller('collections')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class CollectionsController {
  constructor(private readonly collectionsService: CollectionsService) {}

  @Post('create')
  @ApiOperation({ summary: 'Record milk collection' })
  @ApiResponse({ status: 200, description: 'Milk collection recorded successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 404, description: 'Supplier account not found' })
  async createCollection(@CurrentUser() user: User, @Body() createDto: CreateCollectionDto) {
    return this.collectionsService.createCollection(user, createDto);
  }
}

